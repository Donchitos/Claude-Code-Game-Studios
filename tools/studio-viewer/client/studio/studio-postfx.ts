import Phaser from "phaser";

const FRAGMENT_SHADER = `
precision mediump float;

uniform sampler2D uMainSampler;
uniform vec2 uResolution;
uniform float uRadius;
uniform float uBand;
uniform float uSaturation;
uniform float uVignette;

varying vec2 outTexCoord;

const int TAPS = 12;
const float GOLDEN_ANGLE = 2.39996;

void main() {
  float distanceFromCenter = abs(outTexCoord.y - 0.5);
  float blurAmount = smoothstep(uBand, 0.5, distanceFromCenter) * uRadius;
  vec2 texel = 1.0 / uResolution;
  vec3 sum = texture2D(uMainSampler, outTexCoord).rgb;
  for (int tap = 0; tap < TAPS; tap++) {
    float angle = float(tap) * GOLDEN_ANGLE;
    float ring = sqrt((float(tap) + 0.5) / float(TAPS));
    vec2 offset = vec2(cos(angle), sin(angle)) * ring * blurAmount * texel;
    sum += texture2D(uMainSampler, outTexCoord + offset).rgb;
  }
  vec3 color = sum / float(TAPS + 1);
  float luma = dot(color, vec3(0.299, 0.587, 0.114));
  color = mix(vec3(luma), color, 1.0 + uSaturation);
  vec2 centered = outTexCoord - 0.5;
  float edge = smoothstep(0.25, 0.85, length(centered * vec2(1.0, 0.9)));
  color *= 1.0 - edge * uVignette;
  gl_FragColor = vec4(color, 1.0);
}
`;

export const STUDIO_POSTFX_KEY = "StudioPostFx";

export class StudioPostFx extends Phaser.Renderer.WebGL.Pipelines.PostFXPipeline {
  blurRadius = 0;
  band = 0.2;
  saturation = 0;
  vignette = 0;

  constructor(game: Phaser.Game) {
    super({ game, name: STUDIO_POSTFX_KEY, fragShader: FRAGMENT_SHADER });
  }

  override onPreRender(): void {
    this.set1f("uRadius", this.blurRadius);
    this.set1f("uBand", this.band);
    this.set1f("uSaturation", this.saturation);
    this.set1f("uVignette", this.vignette);
    this.set2f("uResolution", this.renderer.width, this.renderer.height);
  }
}
