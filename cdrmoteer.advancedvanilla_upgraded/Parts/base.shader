struct VERT_INPUT
{
	float4 location : POSITION;
	float4 color : COLOR0;
	float2 uv : TEXCOORD0;
};

struct VERT_ANIMATION_INFO
{
	float2 uv : TEXCOORD0;
	float horizontalUVOffsetPerFrame : NORMAL0;
	float animationInterval : NORMAL1;
	float animationStartTime : NORMAL2;
	float animationFrames : NORMAL3;
	float animationClamp : TANGENT0;
};

struct VERT_INPUT_ATLAS
{
	float4 location : POSITION;
	float4 center : POSITION1;
	float4 color : COLOR0;
	float2 spriteUV : TEXCOORD1;
	VERT_ANIMATION_INFO animInfo;
	float rotSpeed : TANGENT1;
};

struct VERT_OUTPUT
{
	float4 location : SV_POSITION;
	float4 color : COLOR0;
	float2 uv : TEXCOORD0;
};

struct VERT_OUTPUT_ATLAS
{
	float4 location : SV_POSITION;
	float4 color : COLOR0;
	float2 uv : TEXCOORD0;
	float2 spriteUV : TEXCOORD1;
};

typedef float4 PIX_OUTPUT;

static const float PI = 3.14159265f;
static const float TWO_PI = PI * 2;
static const float HALF_PI = PI / 2;

float4x4 _transform;
float _time;
float _gameTime;

Texture2D _texture;
SamplerState _texture_SS;
float4 _color = 255;

float wave(float t, float period)
{
	return (cos(t / period * TWO_PI) - 1) / -2;
}

float lerp(float from, float to, float t)
{
	t = min(max(t, 0), 1);
	return from + (to - from) * t;
}

float2 lerp(float2 from, float2 to, float t)
{
	t = min(max(t, 0), 1);
	return from + (to - from) * t;
}

float3 lerp(float3 from, float3 to, float t)
{
	t = min(max(t, 0), 1);
	return from + (to - from) * t;
}

float4 lerp(float4 from, float4 to, float t)
{
	t = min(max(t, 0), 1);
	return from + (to - from) * t;
}

float inverseLerp(float from, float to, float value)
{
	float t = (value - from) / (to - from);
	return min(max(t, 0), 1);
}

float2 rotate(float2 v, float radians)
{
	float cosRot = cos(radians);
	float sinRot = sin(radians);
	return float2(
		v.x * cosRot - v.y * sinRot,
		v.x * sinRot + v.y * cosRot);
}

float2 getAnimatedUVs(VERT_ANIMATION_INFO animInfo)
{
	float2 ret;
	ret.y = animInfo.uv.y;
	int frame = animInfo.animationClamp != 0 ?
		min((int)((_gameTime - animInfo.animationStartTime) / animInfo.animationInterval), (int)animInfo.animationFrames - 1) :
		(int)((_gameTime - animInfo.animationStartTime) / animInfo.animationInterval % animInfo.animationFrames);
	ret.x = animInfo.uv.x + animInfo.horizontalUVOffsetPerFrame * frame;
	return ret;
}

#ifdef USE_DEFAULT_VERT
VERT_OUTPUT vert(in VERT_INPUT input)
{
	VERT_OUTPUT output;
	output.location = mul(input.location, _transform);
	output.color = input.color * _color;
	output.uv = input.uv;
	return output;
}
#endif

#ifdef USE_DEFAULT_VERT_ATLAS
VERT_OUTPUT_ATLAS vert(in VERT_INPUT_ATLAS input)
{
	VERT_OUTPUT_ATLAS output;
	input.location.xy = rotate(input.location.xy - input.center.xy, _gameTime * input.rotSpeed) + input.center.xy;
	output.location = mul(input.location, _transform);
	output.color = input.color * _color;
	output.uv = getAnimatedUVs(input.animInfo);
	output.spriteUV = input.spriteUV;
	return output;
}
#endif

#ifdef USE_UNANIMATED_VERT_ATLAS
VERT_OUTPUT_ATLAS vert(in VERT_INPUT_ATLAS input)
{
	VERT_OUTPUT_ATLAS output;
	output.location = mul(input.location, _transform);
	output.color = input.color;
	output.uv = input.animInfo.uv;
	output.spriteUV = input.spriteUV;
	return output;
}
#endif

float4 swapAllegianceColor(float4 pixel, float4 allegianceColor)
{
	if(pixel.g - pixel.r > .05 && abs(pixel.r - pixel.b) < .25) // Replace green pixels with allegiance color.
	{
		float3 scaledAllegianceColor = allegianceColor.rgb * pixel.g;
		float desaturation = pixel.r / pixel.g; // works because pixel.r == pixel.b (approximately)
		float desaturationValue = max(scaledAllegianceColor.r, max(scaledAllegianceColor.g, scaledAllegianceColor.b));
		float3 desaturationColor = float3(desaturationValue, desaturationValue, desaturationValue);
		pixel.rgb = scaledAllegianceColor * (1 - desaturation) + desaturationColor * desaturation;
	}
	return pixel;
}

#ifdef USE_DEFAULT_PIX
PIX_OUTPUT pix(in VERT_OUTPUT input) : SV_TARGET
{
	float4 ret = _texture.Sample(_texture_SS, input.uv) * input.color;
	if (ret.a <= 0)
		discard;
	return ret;
}
#endif

#ifdef USE_DEFAULT_PIX_ATLAS
PIX_OUTPUT pix(in VERT_OUTPUT_ATLAS input) : SV_TARGET
{
	float4 ret = _texture.Sample(_texture_SS, input.uv) * input.color;
	if (ret.a <= 0)
		discard;
	return ret;
}
#endif
