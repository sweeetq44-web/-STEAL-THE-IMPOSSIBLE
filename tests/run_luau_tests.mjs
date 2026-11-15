import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const { LuauState } = await import("/tmp/rblx-test/node_modules/luau-web/src/index.js");

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");
const srcRoot = path.join(repoRoot, "src");

function walkLuauFiles(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...walkLuauFiles(full));
    } else if (entry.isFile() && entry.name.endsWith(".luau")) {
      out.push(full);
    }
  }
  return out;
}

const luauFiles = walkLuauFiles(srcRoot);
console.log(`Found ${luauFiles.length} .luau files under src/`);

const sourcesByKey = {};
for (const full of luauFiles) {
  const rel = path.relative(srcRoot, full).replace(/\\/g, "/").replace(/\.luau$/, "");
  sourcesByKey[rel] = fs.readFileSync(full, "utf8");
}

// Step 1: Individually compile EVERY .luau file in src/ with official Luau compiler
const compileCheckState = await LuauState.createAsync();
let compileFailures = 0;
for (const [key, src] of Object.entries(sourcesByKey)) {
  try {
    compileCheckState.loadstring(src, `${key}.luau`, true);
  } catch (err) {
    compileFailures++;
    console.error(`COMPILE ERROR in ${key}.luau:\n`, err.message || err);
  }
}

if (compileFailures > 0) {
  console.error(`\n❌ ${compileFailures} file(s) failed Luau compilation!`);
  process.exit(1);
}
console.log(`✅ All ${luauFiles.length} .luau files compiled cleanly with official Luau compiler!\n`);

// Step 2: Bundle Mock + Shared/Server/Client modules + Test Suite into pure Luau (zero re-entrant JS calls)
const mockSrc = fs.readFileSync(path.join(__dirname, "roblox_mock.luau"), "utf8").replace(/^--!strict\s*/, "");
const suiteSrc = fs.readFileSync(path.join(__dirname, "test_suite.luau"), "utf8").replace(/^--!strict\s*/, "");

const ROBLOX_GLOBALS = [
  "game",
  "workspace",
  "Instance",
  "Vector3",
  "Vector2",
  "CFrame",
  "Color3",
  "UDim",
  "UDim2",
  "NumberRange",
  "ColorSequence",
  "NumberSequence",
  "NumberSequenceKeypoint",
  "TweenInfo",
  "Enum",
  "Random",
  "task",
  "warn",
];

const globalParams = ROBLOX_GLOBALS.join(", ");
const globalArgs = ROBLOX_GLOBALS.map((g) => `Mock.Globals.${g}`).join(", ");

const moduleDefs = [];
for (const [key, rawSrc] of Object.entries(sourcesByKey)) {
  const cleanSrc = rawSrc.replace(/^--!strict\s*/, "");
  moduleDefs.push(
    `MODULES[${JSON.stringify(key)}] = function(script, require, ${globalParams})\n${cleanSrc}\nend`
  );
}

const bundle = `
local Mock = (function()
${mockSrc}
end)()

local InstanceNew = Mock.Globals.Instance.new
local game = Mock.Globals.game
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")

local Shared = InstanceNew("Folder", "Shared")
Shared.Parent = ReplicatedStorage
local ServerFolder = InstanceNew("Folder", "Server")
ServerFolder.Parent = ServerScriptService
local ServicesFolder = InstanceNew("Folder", "Services")
ServicesFolder.Parent = ServerFolder
local ClientFolder = InstanceNew("Folder", "Client")
ClientFolder.Parent = StarterPlayerScripts
local ControllersFolder = InstanceNew("Folder", "Controllers")
ControllersFolder.Parent = ClientFolder

local MODULES = {}
${moduleDefs.join("\n")}

local nodeByKey = {}
for key, _ in pairs(MODULES) do
    local parts = string.split(key, "/")
    if parts[1] == "ReplicatedStorage" and parts[2] == "Shared" then
        local ms = InstanceNew("ModuleScript", parts[3])
        ms.Parent = Shared
        ms._moduleKey = key
        nodeByKey[key] = ms
    elseif parts[1] == "ServerScriptService" and parts[2] == "Server" and parts[3] == "Services" then
        local ms = InstanceNew("ModuleScript", parts[4])
        ms.Parent = ServicesFolder
        ms._moduleKey = key
        nodeByKey[key] = ms
    elseif parts[1] == "StarterPlayer" and parts[3] == "Client" and parts[4] == "Controllers" then
        local ms = InstanceNew("ModuleScript", parts[5])
        ms.Parent = ControllersFolder
        ms._moduleKey = key
        nodeByKey[key] = ms
    end
end

local cache = {}
local requireImpl
local function loadByKey(key)
    if cache[key] ~= nil then
        return cache[key]
    end
    local fn = MODULES[key]
    assert(fn ~= nil, "Missing module: " .. tostring(key))
    local res = fn(nodeByKey[key], requireImpl, ${globalArgs})
    cache[key] = res
    return res
end

requireImpl = function(target)
    if type(target) == "string" then
        return loadByKey(target)
    end
    assert(type(target) == "table" and target._moduleKey ~= nil, "Invalid require target: " .. tostring(target))
    return loadByKey(target._moduleKey)
end

local runSuite = (function()
${suiteSrc}
end)()

local ok = runSuite(loadByKey, Mock)
assert(ok == true, "One or more Luau test assertions failed!")
print("🎉 ALL LUAU END-TO-END TESTS PASSED!")
`;

const runtimeState = await LuauState.createAsync();
const runFn = runtimeState.loadstring(bundle, "steal_the_impossible_tests.luau", true);
await runFn();
