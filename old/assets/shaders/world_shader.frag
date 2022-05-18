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


uniform vec4 ambient_color;

vec4 color(vec4 graphicsColor, sampler2D image, vec2 uv) {
	vec4 baseColor = graphicsColor * lovrDiffuseColor * lovrVertexColor * texture(image, uv);
	return baseColor * ambient_color;
}
