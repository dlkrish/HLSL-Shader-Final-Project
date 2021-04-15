using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace SimpleEngine
{
    public class SimpleEngine : Game
    {
        /*
        public class Skybox
        {
            private Model skyBox;
            public TextureCube skyBoxTexture;
            private Effect skyBoxEffect;
            private float size = 50f;

            public Skybox(string[] skyboxTextures, ContentManager Content, GraphicsDevice g)
            {
                skyBox = Content.Load<Model>("skybox/cube");
                skyBoxTexture = new TextureCube(g, 512, false, SurfaceFormat.Color);
                byte[] data = new byte[512 * 512 * 4];
                Texture2D tempTexture = Content.Load<Texture2D>(skyboxTextures[0]);
                tempTexture.GetData<byte>(data);
                skyBoxTexture.SetData<byte>(CubeMapFace.NegativeX, data);
                tempTexture = Content.Load<Texture2D>(skyboxTextures[1]);
                tempTexture.GetData<byte>(data);
                skyBoxTexture.SetData<byte>(CubeMapFace.PositiveX, data);

                skyBoxEffect = Content.Load<Effect>("skybox/Skybox");
            }

            public void Draw(Matrix view, Matrix projection, Vector3 cameraPosition)
            {
                foreach (EffectPass pass in skyBoxEffect.CurrentTechnique.Passes)
                {
                    foreach (ModelMesh mesh in skyBox.Meshes)
                    {
                        foreach (ModelMeshPart part in mesh.MeshParts)
                        {
                            part.Effect = skyBoxEffect;
                            part.Effect.Parameters["World"].SetValue(
                            Matrix.CreateScale(size) *
                            Matrix.CreateTranslation(cameraPosition));
                            part.Effect.Parameters["View"].SetValue(view);
                            part.Effect.Parameters["Projection"].SetValue(projection);
                            part.Effect.Parameters["SkyBoxTexture"].SetValue(skyBoxTexture);
                            part.Effect.Parameters["CameraPosition"].SetValue(cameraPosition);
                        }

                        mesh.Draw();
                    }
                }
            }
        }
        */
    }
}
