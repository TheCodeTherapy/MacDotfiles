// #define CURVE 21.0, 17.0
#define BLOOM_INTENSITY 0.17

// Radial bloom samples
const vec3[24] samples = {
  vec3(+0.1693761725038636, +0.9855514761735895, +1.0000000000000000),
  vec3(-1.3330708309629430, +0.4721463328627773, +0.7071067811865475),
  vec3(-0.8464394909806497, -1.5111387057806500, +0.5773502691896258),
  vec3(+1.5541556807284630, -1.2588090085709776, +0.5000000000000000),
  vec3(+1.6813643775894610, +1.4741145918052656, +0.4472135954999579),
  vec3(-1.2795157692199817, +2.0887411032287840, +0.4082482904638631),
  vec3(-2.4575847530631187, -0.9799373355024756, +0.3779644730092272),
  vec3(+0.5874641440200847, -2.7667464429345077, +0.3535533905932737),
  vec3(+2.9977157033697260, +0.1170493988474515, +0.3333333333333333),
  vec3(+0.4136084245168839, +3.1351121305574803, +0.3162277660168379),
  vec3(-3.1671499337692430, +0.9844599011770256, +0.3015113445777636),
  vec3(-1.5736713846521535, -3.0860263079123245, +0.2886751345948129),
  vec3(+2.8882026483404220, -2.1583061557896213, +0.2773500981126146),
  vec3(+2.7150778983300325, +2.5745586041105715, +0.2672612419124244),
  vec3(-2.1504069972377464, +3.2211410627650165, +0.2581988897471611),
  vec3(-3.6548858794907493, -1.6253643308191343, +0.2500000000000000),
  vec3(+1.0130775986052671, -3.9967078676335834, +0.2425356250363329),
  vec3(+4.2297236736072570, +0.3308136105518156, +0.2357022603955158),
  vec3(+0.4010779029117383, +4.3404074135725930, +0.2294157338705617),
  vec3(-4.3191245702360280, 1.15981159969343800, +0.2236067977499789),
  vec3(-1.9209044802827355, -4.1605439521329070, +0.2182178902359924),
  vec3(+3.8639122286635708, -2.6589814382925123, +0.2132007163556104),
  vec3(+3.3486228404946234, +3.4331800232609000, +0.2085144140570747),
  vec3(-2.8769733643574344, +3.9652268864187157, +0.2041241452319315)
};

// Standard luminosity calculation
float lum(vec4 c) {
  return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
}

// Dither pattern using 4x4 Bayer matrix
float ditherPos(vec2 coord, float multiplier) {
  const int indexMatrix4x4[16] = int[16](
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5
  );
  vec2 scaledCoord = coord / multiplier;
  int x = int(mod(scaledCoord.x, 4.0));
  int y = int(mod(scaledCoord.y, 4.0));
  return float(indexMatrix4x4[x + y * 4]) / 16.0;
}

// Box blur with 4 samples in a cross/plus pattern
vec3 sampleBox(sampler2D tex, vec2 uv, float delta) {
  vec2 texelSize = 1.0 / iResolution.xy;
  vec4 offset = texelSize.xyxy * vec2(-delta, delta).xxyy;
  
  vec3 result = vec3(0.0);
  result += texture(tex, uv + offset.xy).rgb; // top-left
  result += texture(tex, uv + offset.zy).rgb; // top-right
  result += texture(tex, uv + offset.xw).rgb; // bottom-left
  result += texture(tex, uv + offset.zw).rgb; // bottom-right
  
  return result * 0.25; // avg of 4 samples
}

// Progressive downsampling
vec3 downsampleBox13(sampler2D tex, vec2 uv) {
  vec2 texelSize = 1.0 / iResolution.xy;
  vec2 finalOffset = texelSize * 1.0;
  
  vec3 result = vec3(0.0);
  
  // Center sample
  result = texture(tex, uv).rgb * 0.125;
  
  // Inner box (4 samples)
  vec2 offset = finalOffset;
  result += texture(tex, uv + vec2(-offset.x, -offset.y)).rgb * 0.125;
  result += texture(tex, uv + vec2( offset.x, -offset.y)).rgb * 0.125;
  result += texture(tex, uv + vec2(-offset.x,  offset.y)).rgb * 0.125;
  result += texture(tex, uv + vec2( offset.x,  offset.y)).rgb * 0.125;
  
  // Outer box (4 samples at double distance)
  offset *= 2.0;
  result += texture(tex, uv + vec2(-offset.x, -offset.y)).rgb * 0.0625;
  result += texture(tex, uv + vec2( offset.x, -offset.y)).rgb * 0.0625;
  result += texture(tex, uv + vec2(-offset.x,  offset.y)).rgb * 0.0625;
  result += texture(tex, uv + vec2( offset.x,  offset.y)).rgb * 0.0625;
  
  // Edge samples (4 samples)
  offset = texelSize * 1.5;
  result += texture(tex, uv + vec2(0.0, -offset.y)).rgb * 0.0625;
  result += texture(tex, uv + vec2(0.0,  offset.y)).rgb * 0.0625;
  result += texture(tex, uv + vec2(-offset.x, 0.0)).rgb * 0.0625;
  result += texture(tex, uv + vec2( offset.x, 0.0)).rgb * 0.0625;
  
  return result;
}

// Progressive bloom with thresholding
vec4 progressiveBloom(sampler2D tex, vec2 uv) {
  vec4 color = texture(tex, uv);
  
  // Pass 1: Downsample
  vec3 bloom = downsampleBox13(tex, uv);
  
  // Pass 2-4: Apply blur at increasing radii
  bloom += sampleBox(tex, uv, 1.0) * 0.4;
  bloom += sampleBox(tex, uv, 2.0) * 0.3;
  bloom += sampleBox(tex, uv, 3.0) * 0.2;
  
  // Extract bright areas only for bloom (soft threshold)
  float brightness = lum(vec4(bloom, 1.0));
  float threshold = 0.3;
  float softness = 0.5;
  
  // Soft threshold curve (prevents harsh cutoffs)
  float knee = threshold * softness;
  float soft = brightness - threshold + knee;
  soft = clamp(soft, 0.0, 2.0 * knee);
  soft = soft * soft / (4.0 * knee + 0.00001);
  float contribution = max(soft, brightness - threshold);
  contribution /= max(brightness, 0.00001);
  
  bloom *= contribution;
  color.rgb += bloom * BLOOM_INTENSITY;
  
  return color;
}

// Naive radial bloom using precomputed samples
vec4 radialBloom(sampler2D tex, vec2 uv) {
  vec4 color = textureLod(tex, uv, 0.0);
  vec4 original = color;
  vec2 step = vec2(1.414) / iResolution.xy;

  for (int i = 0; i < 24; i++) {
    vec3 s = samples[i] * 0.7;
    vec4 c = texture(tex, uv + s.xy * step);
    float l = lum(c);
    if (l > 0.2) {
      color += l * s.z * c * 0.05;
    }
  }
  return color - original;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 ouv = uv;

  #ifdef CURVE
    uv = (uv - 0.5) * 2.0;
    uv.xy *= 1.0 + pow((abs(vec2(uv.y, uv.x)) / vec2(CURVE)), vec2(2.0));
    uv = (uv / 2.0) + 0.5;
  #endif

  vec4 tex = texture(iChannel0, uv);
  vec4 progBloom = progressiveBloom(iChannel0, uv);
  vec4 radBloom = radialBloom(iChannel0, uv) - tex;
  fragColor = tex + (progBloom * 0.8 + radBloom) * 1.75;
  fragColor = mix(fragColor, fragColor * fragColor, 0.125);
  fragColor = mix(tex, fragColor, 0.5);
}
