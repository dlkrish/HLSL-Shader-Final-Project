float4x4 World;
float4x4 View;
float4x4 Projection;
float4x4 WorldInverseTranspose;

float red;
float green;
float blue;
float boldness;

///////////// Depth and Normal Map /////////////////
struct VertexShaderInput
{
	float4 Position : POSITION0;
	float4 Position2D : TEXCOORD0;
	float4 Normal: NORMAL;
};

struct VertexShaderOutput
{
	float4 Position : POSITION0;
	float4 Position2D : TEXCOORD0;
	float3 Normal: TEXCOORD1;
};

VertexShaderOutput DepthAndNormalVS(VertexShaderInput input)
{
	VertexShaderOutput output;
	output.Position = mul(mul(mul(input.Position, World), View), Projection);
	output.Position2D = output.Position;
	output.Normal = normalize(mul(input.Normal, WorldInverseTranspose).xyz);
	return output;
}

float4 DepthAndNormalPS(VertexShaderOutput input) : COLOR0
{
	float4 projTexCoord = input.Position2D / input.Position2D.w;
	projTexCoord.xy = 0.5 * projTexCoord.xy + float2(0.5, 0.5);
	projTexCoord.y = 1.0 - projTexCoord.y; 
	float depth = 1 - projTexCoord.z; 
	float4 color;
	color.rgb = (normalize(input.Normal.xyz)) / 2.0f + 0.5f; 
	color.a = depth * 100; 
	return color;
}

technique DepthAndNormal
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 PhongVS();
		PixelShader = compile ps_4_0 DepthAndNormalPS();
	}
};

//////////// End Depth and Normal ////////////////

//////////// Phong //////////////////
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
////////// End Phong //////////////////

/////////// Edge Map /////////////////////
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

EdgeOutput EdgeDetectionVS(EdgeInput input) 
{
	EdgeOutput output;
	output.pos = mul(mul(mul(input.Position, World), View), Projection);
	output.UV0 = input.TexCoords;
	output.UV1 = float4(EdgeSize / dim.x, 0, 0, 1 / dim.y);
	return output;
}

float4 EdgeDetectionPS(EdgeOutput input) : COLOR0
{
	float4 A = tex2D(gBuffer, input.UV0 + input.UV1.xy);
	A.xyz = normalize((A.xyz*2.0) - 1.0);

	float4 C = tex2D(gBuffer, input.UV0 - input.UV1.xy);
	C.xyz = normalize((C.xyz*2.0) - 1.0);

	float4 F = tex2D(gBuffer, input.UV0 + input.UV1.zw);
	F.xyz = normalize((F.xyz*2.0) - 1.0);

	float4 H = tex2D(gBuffer, input.UV0 - input.UV1.zw);
	H.xyz = normalize((H.xyz*2.0) - 1.0);

	float4 color;
	color.x = 0.5 * (dot(A.xyz, H.xyz) + dot(C.xyz, F.xyz));
	color.y = (1.0 - 0.5*abs(A.w - H.w)) * (1.0 - 0.5*abs(C.w - F.w));
	color.z = color.x*color.y;

	//Make all lines one color

	//Make y value of all greenish pixels 0 to make back edges black
	if (color.y > color.x && color.y > color.z)
	{
		color.y = 0;
	}

	//Get all edge pixels based on boldness
	if (color.x < boldness && color.y < boldness && color.z < boldness)
	{
		color.x = red;
		color.y = green;
		color.z = blue;
		color.w = 1;
	}

	//Set all other pixels to white
	else
	{
		color.x = 1;
		color.y = 1;
		color.z = 1;
	}

	return color;
}

technique EdgeMap
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 EdgeDetectionVS();
		PixelShader = compile ps_4_0 EdgeDetectionPS();
	}
};
////////////////////////////////////////////////////////////

/////////// Sketchy Drawing ////////////////////////////////

technique SketchyDrawing
{
	pass Pass1
	{
		VertexShader = compile vs_4_0 EdgeDetectionVS();
		PixelShader = compile ps_4_0 EdgeDetectionPS();
	}
};
////////////////////////////////////////////////////////////