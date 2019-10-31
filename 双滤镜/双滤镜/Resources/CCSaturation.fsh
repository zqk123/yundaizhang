
varying lowp vec2 textureCoordinate;
uniform sampler2D inputImageTexture;
uniform lowp float saturation;


const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{

    lowp vec4 source = texture2D(inputImageTexture, textureCoordinate);

    lowp float luminance = dot(source.rgb, luminanceWeighting);

    lowp vec3 greyScaleColor = vec3(luminance,0,0);
    gl_FragColor = vec4(mix(greyScaleColor, source.rgb, saturation), source.w);
}


