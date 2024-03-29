
varying lowp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
const lowp vec3 W = vec3(0.2125, 0.7154, 0.0721);
void main()
{
   lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
   lowp float luminance = dot(textureColor.rgb, W);

    gl_FragColor = vec4(vec3(luminance), textureColor.a);
}
