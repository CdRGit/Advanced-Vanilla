#define USE_DEFAULT_VERT
#include "./Data/base.shader"

Texture2D _waveTex;
SamplerState _waveTex_SS;
float _waveSpeed;
float _waveAlpha;
float _waveCurveInterval;
float _waveCurveMagnitude;
float _waveCurveUOffsetPerSecond;
float _randomWaveTimeOffset;
float _randomWaveUOffset;
float4 _fullPowerColor = 255;
float4 _lowPowerColor = 255;
float _powerLevel;
float _lowPowerThicknessExponent;

PIX_OUTPUT pix(in VERT_OUTPUT input) : SV_TARGET
{
	float4 baseColor = _texture.Sample(_texture_SS, float2(input.uv.x, pow(abs(input.uv.y), _lowPowerThicknessExponent + (1 - _lowPowerThicknessExponent) * _powerLevel)));
	float waveVOffset = (_gameTime + _randomWaveTimeOffset + wave(input.uv.x + _randomWaveUOffset + _gameTime * _waveCurveUOffsetPerSecond, _waveCurveInterval) * _waveCurveMagnitude) * _waveSpeed;
	float4 waveColor = _waveTex.Sample(_waveTex_SS, float2(input.uv.x, input.uv.y + waveVOffset));
	baseColor.a += baseColor.a * waveColor.a * _waveAlpha;
	float4 colorFactor = _fullPowerColor *_powerLevel + _lowPowerColor * (1 - _powerLevel);
	float4 ret = baseColor * input.color * colorFactor;
	ret.rgb *= ret.a;
	if(ret.a <= 0)
		discard;
	return ret;
}
