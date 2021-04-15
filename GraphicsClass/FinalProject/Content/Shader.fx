float4x4 World;
float4x4 View;
float4x4 Projection;
float4x4 WorldInverseTranspose;

float3 LightPosition;
float LightStrength;
float3 LightColor;
float4 DiffuseColor;
float4 AmbientColor;
float AmbientIntensity;
float DiffuseIntensity;
float SpecularIntensity;
float Shininess;
float DepthDistance;
float3 UvwScale;

float3 CameraPosition;

//For Assignment 2
texture SkyboxTexture;
texture HelicopterTexture;
float EtaRatio;
float3 DispersionEtaRatio;
float TextureMixFactor;
float Reflectivity;
float FresBias;
float FresScale;
float FresPower;
float4x4 ModelInverseTranspose;

sampler HelicopterSampler = sampler_state
{
	texture = <HelicopterTexture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

samplerCUBE SkyboxSampler = sampler_state
{
	texture = <SkyboxTexture>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = LINEAR;
	AddressU = Mirror;
	AddressV = Mirror;
};

/*
////////////////////////////////////////// Edge Map ///////////////////////////////////////////////////////////////////////////////
float2 dim; //Texture width and height
texture2D depthAndNormalTex;

float EdgeSize;

sampler2D gBuffer : register (s0) = sampler_state
{
	Texture = <depthAndNormalTex>;
	MipFilter = LINEAR;
	MagFilter = LINEAR;
	MinFilter = LINEAR;
	ADDRESSU = CLAMP;
	ADDRESSV = CLAMP;
};

struct EdgeInput
{
	float4 Position : POSITION0;
	float2 TexCoords : TEXCOORD0;
};

struct EdgeOutput
{
	float4 pos: POSITION0;
	float2 UV0: TEXCOORD0;
	float4 UV1: TEXCOORD1;
};

//Rendering the edge map using the depth and normal map found previously
EdgeOutput EdgeDetectionVS(EdgeInput input)
{
	EdgeOutput output;

	//Orient
	output.pos = mul(mul(mul(input.Position, World), View), Projection);
	output.UV0 = input.TexCoords;

	//Orient to texture size and determine how large of an offset you'd like
	output.UV1 = float4(EdgeSize / dim.x, 0, 0, EdgeSize / dim.y);
	return output;
}

float4 EdgeDetectionPS(EdgeOutput input) : COLOR0
{
	//Using current position, find a pixel nearby using the offset found earlier
	float4 A = tex2D(gBuffer, input.UV0 + input.UV1.xy);
	A.xyz = normalize((A.xyz*2.0) - 1.0);

	//Repeat 3 more times.
	//C
	float4 C = tex2D(gBuffer, input.UV0 - input.UV1.xy);
	C.xyz = normalize((C.xyz*2.0) - 1.0);

	//F
	float4 F = tex2D(gBuffer, input.UV0 + input.UV1.zw);
	F.xyz = normalize((F.xyz*2.0) - 1.0);

	//H
	float4 H = tex2D(gBuffer, input.UV0 - input.UV1.zw);
	H.xyz = normalize((H.xyz*2.0) - 1.0);

	//Detecting edges (and color appropriately)
	float3 color;
	//Dot the half that values together and average them to determine likelihood of it being an edge
	color.x = 0.5 * (dot(A.xyz, H.xyz) + dot(C.xyz, F.xyz));
	//Use the depth value to also determine edges
	color.y = (1.0 - 0.5*abs(A.w - H.w)) * (1.0 - 0.5*abs(C.w - F.w));
	// ?
	color.z = color.x*color.y;
	return float4(color, 1.0);
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

//Z Buffer
cbuffer MatrixBuffer
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
};

struct VertexInputType
{
	float4 position : POSITION;
};

struct PixelInputType
{
	float4 position : SV_POSITION;
	float4 depthPosition : TEXTURE0;
};

PixelInputType DepthVS(VertexInputType input)
{
	PixelInputType output;

	input.position.w = 1.0f;

	float4 worldpos = mul(input.position, World);
	output.position = mul(worldpos, View);
	output.position = mul(output.position, Projection);

	output.depthPosition = output.position;

	return output;
}

float4 DepthPS(PixelInputType input) : SV_TARGET
{
	
	float depthValue;
	float4 color;

	depthValue = input.depthPosition.z / input.depthPosition.w;

	if(depthValue < 0.987f)
	{
		color = float4(0.2f, 0.2f, 0.2f, 1.0f);
	}
	
	if(depthValue > 0.987f + DepthDistance)
	{
		color = float4(0.4f, 0.4f, 0.4f, 1.0f);
	}

	if(depthValue > 0.989f + DepthDistance)
	{
		color = float4(0.6f, 0.6f, 0.6f, 1.0f);
	}

	if (depthValue > 0.99f + DepthDistance)
	{
		color = float4(0.8f, 0.8f, 0.8f, 1.0f);
	}

	if (depthValue > 0.991 + DepthDistance)
	{
		color = float4(1.0f, 1.0f, 1.0f, 1.0f);
	}

	//color = float4(depthValue * DepthDistance, depthValue * DepthDistance, depthValue * DepthDistance, 1.0f);
	return color;
}

technique DepthShader
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 DepthVS();
		PixelShader = compile ps_4_0 DepthPS();
	}
};
//End Z Buffer

//Normal Buffer
sampler TSamplerNoMip = sampler_state
{
	texture = <NormalMap>;
	magfilter = LINEAR;
	minfilter = LINEAR;
	mipfilter = None;
	AddressU = Wrap;
	AddressV = Wrap;
};

struct StandardVertexOutput
{
	float4 Position : POSITION0;
	float3 Normal : NORMAL;
	float3 Tangent : TANGENT0;
	float3 WorldPosition : POSITION1;
	float2 TexCoord : TEXCOORD0;
};

float4 WorldNormalPS(in StandardVertexOutput input) : COLOR
{
	float3 n;
	n = tex2D(TSamplerNoMip, input.TexCoord * UvwScale.xy).rgb;

	n = lerp(float3(0.5, 0.5, 1), n, UvwScale.z);
	n = (n - 0.5) * 2.0;

	float3 N = normalize(input.Normal);
	float3 T = normalize(input.Tangent);
	float3 B = normalize(cross(N, T));
	float3x3 TBN = float3x3(T, B, N);

	float3 world_norm = normalize(mul(normalize(n), TBN));

	return float4((world_norm / 2.0) + 0.5, 1.0);
}

technique NormalShader
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 PhongVS();
		PixelShader = compile ps_4_0 WorldNormalPS();
	}
};
//End Normal Buffer

struct PhongVertexInput
{
	float4 Position : POSITION0;
	float4 Normal : NORMAL;
};

struct PhongVertexOutput
{
	float4 Position : POSITION0;
	float3 Normal : NORMAL;
	float3 WorldPosition : POSITION1;
};

PhongVertexOutput PhongVS(in PhongVertexInput input)
{
	PhongVertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = normalize(mul(input.Normal, WorldInverseTranspose).xyz);
	return output;
}

float4 PhongPS(PhongVertexOutput input) : COLOR
{
	float4 col = float4(0.0, 0.0, 0.0, 1.0);

	float3 LD = LightPosition - input.WorldPosition;
	float oodist2 = 1.0 / dot(LD, LD);

	float3 L = normalize(LD);
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 R = reflect(-L, N);

	col += AmbientIntensity * AmbientColor;
	col += DiffuseIntensity * DiffuseColor * saturate(dot(L, N)) * oodist2 * LightStrength * float4(LightColor, 1.0);
	col += SpecularIntensity * pow(saturate(dot(R, V)), Shininess) * oodist2 * LightStrength * float4(LightColor, 1.0);

	return saturate(col);
}

/////////////// Sketch Color //////////////////

struct SketchColorVertexInput
{
	float4 Position : POSITION0;
	float4 Normal : NORMAL;
};

struct SketchColorVertexOutput
{
	float4 Position : POSITION0;
	float3 Normal : NORMAL;
	float3 WorldPosition : POSITION1;
};

SketchColorVertexOutput SketchColorVS(in SketchColorVertexInput input)
{
	PhongVertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = normalize(mul(input.Normal, WorldInverseTranspose).xyz);
	return output;
}

float4 SketchColorPS(SketchColorVertexOutput input) : COLOR
{
	float4 col = float4(0.0, 0.0, 0.0, 1.0);

	float3 LD = LightPosition - input.WorldPosition;
	float oodist2 = 1.0 / dot(LD, LD);

	float3 L = normalize(LD);
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 R = reflect(-L, N);

	float D = saturate(dot(L, N)) * oodist2 * LightStrength * float4(LightColor, 1.0);
	float S = pow(saturate(dot(R, V)), Shininess) * oodist2 * LightStrength * float4(LightColor, 1.0);

	col += AmbientColor * AmbientIntensity;

	if (D > 0.7) 
	{
		col += DiffuseIntensity * DiffuseColor;
	}
	else if (D > 0.15) 
	{
		col += DiffuseIntensity * DiffuseColor * 0.22;
	}

	if (S > 0.45)
	{
		col = float4(1.0, 1.0, 1.0, 1.0);
	}

	return saturate(col);
}

technique SketchColor
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 SketchColorVS();
		PixelShader = compile ps_4_0 SketchColorPS();
	}
};
///////////////////////////////////////////////

struct GouradVertexInput
{
	float4 Position : POSITION0;
	float4 Normal : NORMAL;
};

struct GouradVertexOutput
{
	float4 Position : POSITION0;
	float4 Color : COLOR0;
};

GouradVertexOutput GouradVS(in GouradVertexInput input)
{
	GouradVertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);

	float4 col = float4(0.0, 0.0, 0.0, 1.0);

	float3 LD = LightPosition - worldpos.xyz;
	float oodist2 = 1.0 / dot(LD, LD);

	float3 L = normalize(LD);
	float3 V = normalize(CameraPosition - worldpos.xyz);
	float3 N = normalize(mul(input.Normal, WorldInverseTranspose).xyz);
	float3 R = reflect(-L, N);

	col += AmbientIntensity * AmbientColor;
	col += DiffuseIntensity * DiffuseColor * saturate(dot(L, N)) * oodist2 * LightStrength * float4(LightColor, 1.0);
	col += SpecularIntensity * pow(saturate(dot(R, V)), Shininess) * oodist2 * LightStrength * float4(LightColor, 1.0);

	output.Color = saturate(col);
	return output;
}

float4 GouradPS(GouradVertexOutput input) : COLOR
{
	return input.Color;
}

PhongVertexOutput BlinnPhongVS(in PhongVertexInput input)
{
	PhongVertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = normalize(mul(input.Normal, WorldInverseTranspose).xyz);
	return output;
}

float4 BlinnPhongPS(PhongVertexOutput input) : COLOR
{
	float4 col = float4(0.0, 0.0, 0.0, 1.0);

	float3 LD = LightPosition - input.WorldPosition;
	float oodist2 = 1.0 / dot(LD, LD);

	float3 L = normalize(LD);
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 H = normalize(L + V);

	col += AmbientIntensity * AmbientColor;
	col += DiffuseIntensity * DiffuseColor * saturate(dot(L, N)) * oodist2 * LightStrength * float4(LightColor, 1.0);
	col += SpecularIntensity * pow(saturate(dot(H, N)), 4 * Shininess) * oodist2 * LightStrength * float4(LightColor, 1.0);

	return saturate(col);
}

PhongVertexOutput SchlickVS(in PhongVertexInput input)
{
	PhongVertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = normalize(mul(input.Normal, WorldInverseTranspose).xyz);
	return output;
}

float4 SchlickPS(PhongVertexOutput input) : COLOR
{
	float4 col = float4(0.0, 0.0, 0.0, 1.0);

	float3 LD = LightPosition - input.WorldPosition;
	float oodist2 = 1.0 / dot(LD, LD);

	float3 L = normalize(LD);
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 R = reflect(-L, N);

	col += AmbientIntensity * AmbientColor;
	col += DiffuseIntensity * DiffuseColor * saturate(dot(L, N)) * oodist2 * LightStrength * float4(LightColor, 1.0);
	float t = saturate(dot(R, V));
	col += SpecularIntensity * t / (Shininess - t * Shininess + t) * oodist2 * LightStrength * float4(LightColor, 1.0);

	return saturate(col);
}

PhongVertexOutput HalfLifeVS(in PhongVertexInput input)
{
	PhongVertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = normalize(mul(input.Normal, WorldInverseTranspose).xyz);
	return output;
}

float4 HalfLifePS(PhongVertexOutput input) : COLOR
{
	float4 col = float4(0.0, 0.0, 0.0, 1.0);

	float3 LD = LightPosition - input.WorldPosition;
	float oodist2 = 1.0 / dot(LD, LD);

	float3 L = normalize(LD);
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 R = reflect(-L, N);

	col += AmbientIntensity * AmbientColor;
	float t = 0.5 * (dot(L, N) + 1);
	col += DiffuseIntensity * DiffuseColor * t * t * oodist2 * LightStrength * float4(LightColor, 1.0);
	col += SpecularIntensity * pow(saturate(dot(R, V)), Shininess) * oodist2 * LightStrength * float4(LightColor, 1.0);

	return saturate(col);
}

//Assignment 2
struct VertexInput
{
	float4 Position : POSITION;
	float4 Normal : NORMAL0;
	float2 TexCoord : TEXCOORD0;
};

struct VertexOutput
{
	float4 Position : POSITION;
	float3 Normal : NORMAL0;
	float2 TexCoord : TEXCOORD0;
	float3 WorldPosition: TEXCOORD1;
};

VertexOutput ReflectionVS(VertexInput input)
{
	VertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = mul(float4(input.Normal.xyz, 0.0), World).xyz;
	output.TexCoord = input.TexCoord;
	return output;
}

float4 ReflectionPS(VertexOutput input) : COLOR
{
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 R = reflect(-V, N);
	float3 col = texCUBE(SkyboxSampler, R).rgb;
	float3 texCol = tex2D(HelicopterSampler, input.TexCoord).rgb;
	float4 HelicopterTexture = tex2D(HelicopterSampler, input.TexCoord);
	return lerp(HelicopterTexture, float4(Reflectivity * lerp(col, texCol, TextureMixFactor), 1.0), 0.5);
}

VertexOutput RefractionVS(VertexInput input)
{
	VertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = mul(float4(input.Normal.xyz, 0.0), World).xyz;
	output.TexCoord = input.TexCoord;
	return output;
}

float4 RefractionPS(VertexOutput input) : COLOR
{
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 T = refract(-V, N, EtaRatio);
	float3 col = texCUBE(SkyboxSampler, T).rgb;
	float3 texCol = tex2D(HelicopterSampler, input.TexCoord).rgb;
	float4 HelicopterTexture = tex2D(HelicopterSampler, input.TexCoord);
	return lerp(HelicopterTexture, float4(lerp(col, texCol, TextureMixFactor), 1.0), 0.5);
}

float4 RefractionDispersionPS(VertexOutput input) : COLOR
{
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 N = normalize(input.Normal);
	float3 TR = refract(-V, N, DispersionEtaRatio.r);
	float3 TG = refract(-V, N, DispersionEtaRatio.g);
	float3 TB = refract(-V, N, DispersionEtaRatio.b);
	float3 col;
	col.r = texCUBE(SkyboxSampler, TR).r;
	col.g = texCUBE(SkyboxSampler, TG).g;
	col.b = texCUBE(SkyboxSampler, TB).b;
	float3 texCol = tex2D(HelicopterSampler, input.TexCoord).rgb;
	float4 HelicopterTexture = tex2D(HelicopterSampler, input.TexCoord);
	return lerp(HelicopterTexture, float4(lerp(col, texCol, TextureMixFactor), 1.0), 0.5);
}

VertexOutput FresnelVS(VertexInput input)
{
	VertexOutput output;
	float4 worldpos = mul(input.Position, World);
	output.Position = mul(mul(worldpos, View), Projection);
	output.WorldPosition = worldpos.xyz;
	output.Normal = mul(float4(input.Normal.xyz, 0.0), World).xyz;
	output.TexCoord = input.TexCoord;
	return output;
}

float3 Fresnel(float3 V, float3 N)
{
	return FresBias + FresScale * pow(1.0f - saturate(dot(V, N)), FresPower);
}

float4 FresnelPS(VertexOutput input) : COLOR
{
	float3 V = normalize(CameraPosition - input.WorldPosition);
	float3 I = -V;
	float3 N = normalize(input.Normal);
	float3 fresnel = Fresnel(V, N);
	float3 R = reflect(I, N);
	float3 TR = refract(-V, N, DispersionEtaRatio.r);
	float3 TG = refract(-V, N, DispersionEtaRatio.g);
	float3 TB = refract(-V, N, DispersionEtaRatio.b);
	float3 TCol;
	TCol.r = texCUBE(SkyboxSampler, TR).r;
	TCol.g = texCUBE(SkyboxSampler, TG).g;
	TCol.b = texCUBE(SkyboxSampler, TB).b;
	float3 RCol = texCUBE(SkyboxSampler, R).rgb;
	float3 fresCol = lerp(TCol, RCol, fresnel);
	float3 decalCol = tex2D(HelicopterSampler, input.TexCoord).rgb;
	float3 col = lerp(fresCol, decalCol, TextureMixFactor);
	float4 HelicopterTexture = tex2D(HelicopterSampler, input.TexCoord);
	return lerp(HelicopterTexture, float4(col, 1.0), 0.5);
}

technique Gourad
{
	pass P0
	{
		VertexShader = compile vs_4_0 GouradVS();
		PixelShader = compile ps_4_0 GouradPS();
	}
};

technique Phong
{
	pass P0
	{
		VertexShader = compile vs_4_0 PhongVS();
		PixelShader = compile ps_4_0 PhongPS();
	}
};

technique PhongBlinn
{
	pass P0
	{
		VertexShader = compile vs_4_0 BlinnPhongVS();
		PixelShader = compile ps_4_0 BlinnPhongPS();
	}
};

technique Schlick
{
	pass P0
	{
		VertexShader = compile vs_4_0 SchlickVS();
		PixelShader = compile ps_4_0 SchlickPS();
	}
};

/*
technique Toon
{
	pass P0
	{
		VertexShader = compile vs_4_0 ToonVS();
		PixelShader = compile ps_4_0 ToonPS();
	}
};
*/

technique HalfLife
{
	pass P0
	{
		VertexShader = compile vs_4_0 HalfLifeVS();
		PixelShader = compile ps_4_0 HalfLifePS();
	}
};

technique Reflection
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 ReflectionVS();
		PixelShader = compile ps_4_0 ReflectionPS();
	}
};

technique Refraction
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 RefractionVS();
		PixelShader = compile ps_4_0 RefractionPS();
	}
};

technique RefractionDispersion
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 RefractionVS();
		PixelShader = compile ps_4_0 RefractionDispersionPS();
	}
};

technique Fresnel
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 FresnelVS();
		PixelShader = compile ps_4_0 FresnelPS();
	}
};