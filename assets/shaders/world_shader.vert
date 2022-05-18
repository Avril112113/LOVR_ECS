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

out vec3 FragmentPos;
out vec3 Normal;

vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
	Normal = lovrNormal * lovrNormalMatrix;
	FragmentPos = vec3(lovrModel * vertex);
	
	return projection * transform * vertex;
}
