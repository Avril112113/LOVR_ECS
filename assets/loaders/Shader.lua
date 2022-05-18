---@param pattern string
---@return string
local function escapePattern(pattern)
	return pattern:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end
local FRAG_HEADER = escapePattern([[
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
local _, FRAG_HEADER_NL_COUNT = select(2, FRAG_HEADER:gsub("\n", ""))
local VERT_HEADER = escapePattern([[
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
local _, VERT_HEADER_NL_COUNT = select(2, VERT_HEADER:gsub("\n", ""))

return {
	-- Called in the asset loader thread, used to retrive and process the data
	threadLoad = function(assetId)
		return {
			-- Added newlines to try preserve error line numbers
			frag = lovr.filesystem.read("assets/shaders/" .. assetId .. ".frag"):gsub(FRAG_HEADER, string.rep("\n", FRAG_HEADER_NL_COUNT)),
			vert = lovr.filesystem.read("assets/shaders/" .. assetId .. ".vert"):gsub(VERT_HEADER, string.rep("\n", VERT_HEADER_NL_COUNT)),
		}
	end,
	-- Called on the main thread, to finalize loading the asset and do processing that can not be done on a thread
	postLoad = function(assetId, asset)
		return lovr.graphics.newShader(asset.vert, asset.frag)
	end,
}