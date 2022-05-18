-- This is running in both a LOVR thread AND the main thread independently

---@class ShaderLoader : AssetLoaderBase
---@diagnostic disable-next-line: undefined-global
local ShaderLoader = class.ShaderLoader(AssetLoaderBase)
---@type table<string, lovr.Texture>
ShaderLoader.assets = nil
ShaderLoader.extensions = {{".vert", ".frag"}}
ShaderLoader.autoload = {
	subpath = "shaders/",
	recursive = true
}

---@param pattern string
---@return string
local function escapePattern(pattern)
	return pattern:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end
ShaderLoader.FRAG_HEADER = escapePattern([[
// Shader header for typing, this is removed before the shader is compiled in LOVR
#version 330
precision highp float;
in vec2 lovrTexCoord;
in vec4 lovrVertexColor;
in vec4 lovrGraphicsColor;
out vec4 lovrCanvas[gl_MaxDrawBuffers];
uniform float lovrMetalness;
uniform float lovrRoughness;
uniform vec4 lovrDiffuseColor;
uniform vec4 lovrEmissiveColor;
uniform sampler2D lovrDiffuseTexture;
uniform sampler2D lovrEmissiveTexture;
uniform sampler2D lovrMetalnessTexture;
uniform sampler2D lovrRoughnessTexture;
uniform sampler2D lovrOcclusionTexture;
uniform sampler2D lovrNormalTexture;
uniform samplerCube lovrEnvironmentTexture;
uniform int lovrViewportCount;
uniform int lovrViewID;
]])
ShaderLoader.VERT_HEADER = escapePattern([[
// Shader header for typing, this is removed before the shader is compiled in LOVR
#version 330
precision highp float;
in vec3 lovrPosition;
in vec3 lovrNormal;
in vec2 lovrTexCoord;
in vec4 lovrVertexColor;
in vec3 lovrTangent;
in uvec4 lovrBones;
in vec4 lovrBoneWeights;
in uint lovrDrawID;
out vec4 lovrGraphicsColor;
uniform mat4 lovrModel;
uniform mat4 lovrView;
uniform mat4 lovrProjection;
uniform mat4 lovrTransform;
uniform mat3 lovrNormalMatrix;
uniform mat3 lovrMaterialTransform;
uniform float lovrPointSize;
uniform mat4 lovrPose[48];
uniform int lovrViewportCount;
uniform int lovrViewID;
const mat4 lovrPoseMatrix = mat4(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
const int lovrInstanceID = 0;
]])

---@param assetPath string @ Full virtual path to the asset
---@return any|boolean, string @ asset|skip, assetId
function ShaderLoader:load(assetPath)
	-- `assetPath` COULD have an extension
	local basePath = assetPath:gsub("%.vert$", ""):gsub("%.frag$", "")
	-- self.loadedPaths[basePath] = true
	local vertCode = self:loadVert(basePath .. ".vert")
	local fragCode = self:loadFrag(basePath .. ".frag")
	return {vertCode, fragCode}, basePath:match("([^/]*)$")
end

function ShaderLoader:loadVert(assetPath)
	if lovr.filesystem.isFile(assetPath) then
		local data = lovr.filesystem.read(assetPath)
		for line in self.VERT_HEADER:gmatch("([^\n]*)") do
			data = data:gsub(line, "")
		end
		return data
	end
	return nil
end
function ShaderLoader:loadFrag(assetPath)
	if lovr.filesystem.isFile(assetPath) then
		local data = lovr.filesystem.read(assetPath)
		for line in self.FRAG_HEADER:gmatch("([^\n]*)") do
			data = data:gsub(line, "")
		end
		return data
	end
	return nil
end

---@param asset any
---@param assetId string
function ShaderLoader:postLoad(asset, assetId)
	-- `asset[1]` OR `asset[2]` COULD be nil, both shouldn't be
	assert(not (asset[1] == nil and asset[2] == nil), "Both shader asset strings from thread was nil")
	-- "\n" ensures it's ALWAYS seen as a file (It's in the LOVR docs, somewhere)
	return lovr.graphics.newShader(asset[1] .. "\n", asset[2] .. "\n")
end

return ShaderLoader
