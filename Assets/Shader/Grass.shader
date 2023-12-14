Shader "Custom/Grass"
{
    //プロパティーブロック。ビルトインと同様に外部から操作可能な設定値を定義できる。
    Properties
    {
        //ここに書いたものがInspectorに表示される。
        _Color("MainColor",Color) = (0,0,0,0)
        _Alpha ("Alpha", Float) = 1
        _AmbientLight ("Ambient Light", Color) = (0.5,0.5,0.5,1)
        _AmbientPower("Ambient Power ", Range(0, 3)) = 1
        _Size ("Size", Float) = 1
        _Frequency("Frequency ", Range(0, 3)) = 1
        _Amplitude("Amplitude", Range(0, 1)) = 0.5
        _WaveSpeed("WaveSpeed",Range(0, 20)) = 10
    }

    //サブシェーダーブロック。ここに処理を書いていく。
    SubShader
    {
        //タグ。サブシェーダーブロック、もしくはパスが実行されるタイミングや条件を記述する。
        Tags
        {
            //レンダリングのタイミング(順番)
            "RenderType" = "Transparent"
            //レンダーパイプラインを指定する。なくても動く。動作環境を制限する役割。
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            //HLSL言語を使うという宣言(おまじない)。ビルトインではCg言語だった。
            HLSLPROGRAM
            //vertという名前の関数がvertexシェーダーです　と宣言してGPUに教える。
            #pragma vertex vert
            //fragという名前の関数がfragmentシェーダーです　と宣言してGPUに教える。
            #pragma fragment frag
            //GPUインスタンシングを有効にする。
            #pragma multi_compile_instancing

            //Core機能をまとめたhlslを参照可能にする。いろんな便利関数や事前定義された値が利用可能となる。
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            //ランダムな値を返す
            float rand(float2 co) //引数はシード値と呼ばれる　同じ値を渡せば同じものを返す
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            //パーリンノイズ
            float perlinNoise(float2 st)
            {
                float2 p = floor(st);
                float2 f = frac(st);
                float2 u = f * f * (3.0 - 2.0 * f);

                float v00 = rand(p + float2(0, 0));
                float v10 = rand(p + float2(1, 0));
                float v01 = rand(p + float2(0, 1));
                float v11 = rand(p + float2(1, 1));

                return lerp(lerp(dot(v00, f - float2(0, 0)), dot(v10, f - float2(1, 0)), u.x),
                            lerp(dot(v01, f - float2(0, 1)), dot(v11, f - float2(1, 1)), u.x),
                            u.y) + 0.5f;
            }

            //頂点シェーダーに渡す構造体。名前は自分で定義可能。
            struct appdata
            {
                //オブジェクト空間における頂点座標を受け取るための変数
                float4 position : POSITION;
                //UV座標を受け取るための変数
                float2 uv : TEXCOORD0;
                //法線を受け取るための変数
                float3 normal : NORMAL;
                //GPUインスタンシングに必要な変数
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //フラグメントシェーダーに渡す構造体。名前は自分で定義可能。
            struct v2f
            {
                //頂点座標を受け取るための変数。
                float4 vertex : SV_POSITION;
                //UV座標を受け取るための変数。
                float2 uv : TEXCOORD0;
                //法線を受け取るための変数。
                float3 normal : NORMAL;
                //GPUインスタンシングに必要な変数
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            //変数の宣言。Propertiesで定義した名前と一致させる。
            float4 _Color;
            float _Alpha;
            float3 _AmbientLight;
            float _AmbientPower;
            float _Size;
            float _Frequency;
            float _Amplitude;
            float _WaveSpeed;


            //頂点シェーダー。引数には事前定義した構造体が渡ってくる。
            v2f vert(appdata v, uint instanceID : SV_InstanceID)
            {
                //先ほど宣言した構造体のオブジェクトを作る。
                v2f o;

                //GPUインスタンシングに必要な変数を設定する。
                UNITY_SETUP_INSTANCE_ID(v);

                //スケールのための行列を計算
                float4x4 scaleMatrix = float4x4(1, 0, 0, 0,
                                                0, _Size * clamp(rand(instanceID), 0.7, 1.0) * 1.2, 0, 0,
                                                0, 0, 1, 0,
                                                0, 0, 0, 1);

                v.position = mul(scaleMatrix, v.position);

                float2 factors = _Time.w * _WaveSpeed + v.uv.xy * _Frequency;
                float2 offsetFactor = sin(factors) * _Amplitude * (v.uv.y) * perlinNoise(_Time * rand(instanceID));

                v.position.xz += offsetFactor.x + offsetFactor.y;
                //"3Dの世界での座標は2D(スクリーン)においてはこの位置になりますよ"　という変換を関数を使って行っている。
                o.vertex = TransformObjectToHClip(v.position);
                //法線を変換。
                o.normal = TransformObjectToWorldNormal(v.normal);

                //変換結果を返す。フラグメントシェーダーへ渡る。
                return o;
            }

            //フラグメントシェーダー。引数には頂点シェーダーで処理された構造体が渡ってくる。
            float4 frag(v2f i) : SV_Target
            {
                float4 col = _Color;

                // ライト情報を取得
                Light light = GetMainLight();
                // ピクセルの法線とライトの方向の内積を計算する
                float t = dot(i.normal, light.direction);
                // 内積の値を0以上の値にする
                t = max(0, t);
                // 拡散反射光を計算する
                float3 diffuseLight = light.color * t;
                // 拡散反射光を反映
                col.rgb *= diffuseLight + _AmbientLight * _AmbientPower;
                // アルファ値を設定
                col.a = _Alpha;
                return col;
            }
            ENDHLSL
        }
    }
}