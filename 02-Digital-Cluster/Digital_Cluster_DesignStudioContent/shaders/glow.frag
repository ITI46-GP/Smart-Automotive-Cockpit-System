uniform sampler2D source;
varying vec2 qt_TexCoord0;

void main() {
    vec4 color = texture2D(source, qt_TexCoord0);

    float glow = smoothstep(0.2, 1.0, color.a);

    vec3 redGlow = vec3(1.0, 0.2, 0.2) * glow;

    gl_FragColor = vec4(color.rgb + redGlow * 0.5, color.a);
}
