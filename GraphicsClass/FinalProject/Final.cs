using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;

namespace FinalProject
{
    public class Final : Game
    {
        GraphicsDeviceManager graphics;
        SpriteBatch spriteBatch;

        SpriteFont font;

        //3D model and shader
        Effect effect;
        Model model;
        Model plane;
        int technique;
        String modelName;

        //3D Matrix
        Matrix view;
        Matrix projection;

        //3D Camera and Light
        Vector3 cameraPosition = new Vector3(0, 0, -10);
        Vector2 angle = new Vector2(0, 0);
        float distance = 15;
        Matrix drag;
        Vector3 offset = new Vector3(0, 0, 0);
        Vector4 diffuseColor = new Vector4(1, 1, 1, 1);
        float lightStrength = 200;

        // object materials
        Vector4 ambient = new Vector4(0, 0, 0, 0);
        Vector4 specularColor = new Vector4(1, 1, 1, 1);
        float ambientIntensity = 0.25f;
        float specularIntensity = 1f;
        float diffuseIntensity = 0.8f;
        float shininess = 10.0f;
        float depthMultiplier = 0f;
        Vector3 lightPosition = new Vector3(5, 10, 8);
        Vector3 lightColor = new Vector3(1, 1, 1);

        //For edge map
        RenderTarget2D renderTarget;
        Texture2D depthNormMap;
        float edgeSize = 3f;
        float red = 0.5f;
        float green = 0.5f;
        float blue = 0.5f;
        float boldness = 0.999f;

        //States
        MouseState previousMouseState;
        KeyboardState previousKeyboardState;

        bool showHelp = true;
        bool showInfo = true;

        public Final()
        {
            graphics = new GraphicsDeviceManager(this);
            Content.RootDirectory = "Content";
            graphics.GraphicsProfile = GraphicsProfile.HiDef;
        }

        protected override void Initialize()
        {
            base.Initialize();
        }

        protected override void LoadContent()
        {
            spriteBatch = new SpriteBatch(GraphicsDevice);

            font = Content.Load<SpriteFont>("Font");

            effect = Content.Load<Effect>("EdgeMap");
            technique = 1;
            model = Content.Load<Model>("cube");
            modelName = "Cube";
            plane = Content.Load<Model>("canvas");
            projection = Matrix.CreatePerspectiveFieldOfView(MathHelper.ToRadians(90), GraphicsDevice.Viewport.AspectRatio, 0.1f, 100);
            previousMouseState = Mouse.GetState();

            //For edge map
            PresentationParameters pp = GraphicsDevice.PresentationParameters;
            renderTarget = new RenderTarget2D(GraphicsDevice, pp.BackBufferWidth, pp.BackBufferHeight, false, SurfaceFormat.Color, DepthFormat.Depth24);          
        }

        protected override void UnloadContent()
        {
        
        }

        protected override void Update(GameTime gameTime)
        {
            if (GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed || Keyboard.GetState().IsKeyDown(Keys.Escape))
                Exit();

            MouseState currentMouseState = Mouse.GetState();

            //Left mouse
            if (currentMouseState.LeftButton == ButtonState.Pressed && previousMouseState.LeftButton == ButtonState.Pressed)
            {
                angle.X -= (currentMouseState.X - previousMouseState.X) * 0.01f;
                angle.Y -= (currentMouseState.Y - previousMouseState.Y) * 0.01f;
            }

            //Right mouse
            if (currentMouseState.RightButton == ButtonState.Pressed && previousMouseState.RightButton == ButtonState.Pressed)
            {
                distance += (previousMouseState.X - currentMouseState.X) * 0.01f;
            }

            //Middle mouse
            if (currentMouseState.MiddleButton == ButtonState.Pressed && previousMouseState.MiddleButton == ButtonState.Released)
            {
                drag = Matrix.CreateRotationX(angle.Y) * Matrix.CreateRotationY(angle.X);
            }

            if (currentMouseState.MiddleButton == ButtonState.Pressed && previousMouseState.MiddleButton == ButtonState.Pressed)
            {
                offset += Vector3.Transform(new Vector3((previousMouseState.X - currentMouseState.X) * 0.01f, (previousMouseState.Y - currentMouseState.Y) * -0.01f, 0), drag);
            }

            //Change edge size
            if (Keyboard.GetState().IsKeyDown(Keys.E) && Keyboard.GetState().IsKeyDown(Keys.LeftShift) && edgeSize >= 0)
            {
                edgeSize -= 0.1f;
            }

            else if (Keyboard.GetState().IsKeyDown(Keys.E) && edgeSize <= 10)
            {
                edgeSize += 0.1f;
            }

            //Change R value
            if (Keyboard.GetState().IsKeyDown(Keys.R) && Keyboard.GetState().IsKeyDown(Keys.LeftShift) && red > 0f)
            {
                red -= 0.01f;
            }

            else if (Keyboard.GetState().IsKeyDown(Keys.R) && red <= 0.9f)
            {
                red += 0.01f;
            }

            //Change G Value
            if (Keyboard.GetState().IsKeyDown(Keys.G) && Keyboard.GetState().IsKeyDown(Keys.LeftShift) && green > 0f)
            {
                green -= 0.01f;
            }

            else if (Keyboard.GetState().IsKeyDown(Keys.G) && green <= 0.9f)
            {
                green += 0.01f;
            }

            //Change B Value
            if (Keyboard.GetState().IsKeyDown(Keys.B) && Keyboard.GetState().IsKeyDown(Keys.LeftShift) && blue > 0f)
            {
                blue -= 0.01f;
            }

            else if (Keyboard.GetState().IsKeyDown(Keys.B) && blue <= 0.9f)
            {
                blue += 0.01f;
            }

            //Change Boldness
            if (Keyboard.GetState().IsKeyDown(Keys.Q) && Keyboard.GetState().IsKeyDown(Keys.LeftShift) && boldness > 0f)
            {
                boldness -= 0.001f;
            }

            else if (Keyboard.GetState().IsKeyDown(Keys.Q) && boldness < 0.999f)
            {
                boldness += 0.001f;
            }

            //Cube
            if (Keyboard.GetState().IsKeyDown(Keys.D1))
            {
                model = Content.Load<Model>("Cube");
                modelName = "Cube";
            }

            //Sphere
            if (Keyboard.GetState().IsKeyDown(Keys.D2))
            {
                model = Content.Load<Model>("Sphere");
                modelName = "Sphere";
            }

            //Torus
            if (Keyboard.GetState().IsKeyDown(Keys.D3))
            {
                model = Content.Load<Model>("Torus");
                modelName = "Torus";
            }

            //Teapot
            if (Keyboard.GetState().IsKeyDown(Keys.D4))
            {
                model = Content.Load<Model>("Teapot");
                modelName = "Teapot";
            }

            //Bunny
            if (Keyboard.GetState().IsKeyDown(Keys.D5))
            {
                model = Content.Load<Model>("bunny");
                modelName = "Bunny";
            }

            //Plane
            if (Keyboard.GetState().IsKeyDown(Keys.D6))
            {
                model = Content.Load<Model>("Plane");
                modelName = "Plane";
            }

            //Depth Shader
            if (Keyboard.GetState().IsKeyDown(Keys.F2))
            {
                effect = Content.Load<Effect>("Shader");
                technique = 0;
            }

            //Normal Shader
            if (Keyboard.GetState().IsKeyDown(Keys.F3))
            {
                effect = Content.Load<Effect>("Shader");
                technique = 1;
            }

            
            //DepthAndNormal
            if (Keyboard.GetState().IsKeyDown(Keys.F4))
            {
                effect = Content.Load<Effect>("EdgeMap");
                technique = 0;
            }

            
            //Edge Rendering
            if (Keyboard.GetState().IsKeyDown(Keys.F1))
            {
                effect = Content.Load<Effect>("EdgeMap");
                technique = 1;
                effect.CurrentTechnique = effect.Techniques["EdgeMap"];
            }

            //Update matrices
            cameraPosition = offset + Vector3.Transform(new Vector3(0, 0, distance), Matrix.CreateRotationX(angle.Y) * Matrix.CreateRotationY(angle.X));
            view = Matrix.CreateLookAt(cameraPosition, offset, Vector3.Transform(new Vector3(0, 1, 0), Matrix.CreateRotationX(angle.Y) * Matrix.CreateRotationY(angle.X)));
            previousMouseState = currentMouseState;

            //Toggle info
            if (Keyboard.GetState().IsKeyDown(Keys.OemQuestion) && !previousKeyboardState.IsKeyDown(Keys.OemQuestion))
            {
                showHelp = !showHelp;
            }

            if (Keyboard.GetState().IsKeyDown(Keys.H) && !previousKeyboardState.IsKeyDown(Keys.H))
            {
                showInfo = !showInfo;
            }

            previousKeyboardState = Keyboard.GetState();

            base.Update(gameTime);
        }

        protected override void Draw(GameTime gameTime)
        {
            GraphicsDevice.Clear(Color.CornflowerBlue);
            GraphicsDevice.BlendState = BlendState.Opaque;
            GraphicsDevice.DepthStencilState = new DepthStencilState();

            //////////// Edge Map //////////////////
            if (effect.CurrentTechnique.Name == "DepthAndNormal" || effect.CurrentTechnique.Name == "EdgeMap" || effect.CurrentTechnique.Name == "SketchyDrawing")
            {
                GraphicsDevice.SetRenderTarget(renderTarget);
                GraphicsDevice.Clear(ClearOptions.Target | ClearOptions.DepthBuffer, Color.CornflowerBlue, 1.0f, 0);

                //Draw depth/normal map
                DrawDepthAndNormalMap();

                GraphicsDevice.SetRenderTarget(null);
                depthNormMap = (Texture2D)renderTarget;

                if (technique == 1)
                {
                    DrawEdgeMap();
                }

                else if (technique == 0)
                {
                    using (SpriteBatch sprite = new SpriteBatch(GraphicsDevice))
                    {
                        sprite.Begin();
                        sprite.Draw(depthNormMap, new Vector2(0, 0), null,Color.White, 0, new Vector2(0, 0), 1f, SpriteEffects.None, 0);
                        sprite.End();
                    }
                }

                //Final Shader
                else if (technique == 3)
                {
                    DrawSketchyDrawing();
                }

                depthNormMap = null;
            }
            //////////////////////////////////////////

            else
            {
                effect.CurrentTechnique = effect.Techniques[technique];

                foreach (EffectPass pass in effect.CurrentTechnique.Passes)
                {
                    foreach (ModelMesh mesh in model.Meshes)
                    {
                        foreach (ModelMeshPart part in mesh.MeshParts)
                        {
                            effect.Parameters["World"].SetValue(mesh.ParentBone.Transform);
                            effect.Parameters["View"].SetValue(view);
                            effect.Parameters["Projection"].SetValue(projection);
                            Matrix worldInverseTransposeMatrix = Matrix.Transpose(Matrix.Invert(mesh.ParentBone.Transform));
                            effect.Parameters["WorldInverseTranspose"].SetValue(worldInverseTransposeMatrix);


                            effect.Parameters["CameraPosition"].SetValue(cameraPosition);
                            effect.Parameters["DiffuseColor"].SetValue(diffuseColor);
                            effect.Parameters["AmbientColor"].SetValue(ambient);
                            effect.Parameters["AmbientIntensity"].SetValue(ambientIntensity);
                            effect.Parameters["DiffuseIntensity"].SetValue(diffuseIntensity);
                            effect.Parameters["SpecularIntensity"].SetValue(specularIntensity);
                            effect.Parameters["Shininess"].SetValue(shininess);
                            effect.Parameters["LightPosition"].SetValue(lightPosition);
                            effect.Parameters["LightStrength"].SetValue(lightStrength);
                            effect.Parameters["LightColor"].SetValue(lightColor);
                            effect.Parameters["DepthDistance"].SetValue(depthMultiplier);

                            Matrix worldInverseTranspose = Matrix.Transpose(Matrix.Invert(mesh.ParentBone.Transform));
                            effect.Parameters["WorldInverseTranspose"].SetValue(worldInverseTranspose);

                            pass.Apply();
                            GraphicsDevice.SetVertexBuffer(part.VertexBuffer);
                            GraphicsDevice.Indices = part.IndexBuffer;

                            GraphicsDevice.DrawIndexedPrimitives(
                                PrimitiveType.TriangleList,
                                part.VertexOffset,
                                part.StartIndex,
                                part.PrimitiveCount);
                        }
                    }
                }
            }

            spriteBatch.Begin();

            if (showHelp == true)
            {
                spriteBatch.DrawString(font, "Left Mouse: Rotate Camera\nRight Mouse: Change Camera Distance\nMiddle Mouse: Translate Camera\nChange Edge Size: E (+ Shift to Decrease)\nChange RGB Values: R, G, and B keys (+ Shift to Decrease)\nChange Boldness: Q(+ Shift to Decrease)\nChange Models: Keys 1 - 6\nChange Shader Technique: f1-f6\nToggle Help: H\nToggle Info: ?", new Vector2(10, 10), Color.Green);
            }

            if (showInfo == true)
            {
                spriteBatch.DrawString(font, "Camera Angle: " + angle + "\nDistance: " + distance + "\nOffset: " + offset + "\nEdge Size: " + edgeSize + "\nR Value: " + red + "\nG Value: " + green + "\nB Value: " + blue + "\nBoldness: " + boldness + "\nCurrent Technique: " + effect.CurrentTechnique.Name + "\nCurrent model: " + modelName, new Vector2(500, 10), Color.Green);
            }

            spriteBatch.End();

            base.Draw(gameTime);
        }

        //Draw Depth and Normal Map
        private void DrawDepthAndNormalMap()
        {
            effect.CurrentTechnique = effect.Techniques["DepthAndNormal"];

            foreach (EffectPass pass in effect.CurrentTechnique.Passes)
            {
                foreach (ModelMesh mesh in model.Meshes)
                {
                    foreach (ModelMeshPart part in mesh.MeshParts)
                    {
                        effect.Parameters["World"].SetValue(mesh.ParentBone.Transform);
                        effect.Parameters["View"].SetValue(view);
                        effect.Parameters["Projection"].SetValue(projection);
                        Matrix worldInverseTransposeMatrix = Matrix.Transpose(Matrix.Invert(mesh.ParentBone.Transform));
                        effect.Parameters["WorldInverseTranspose"].SetValue(worldInverseTransposeMatrix);
                        pass.Apply();
                        GraphicsDevice.SetVertexBuffer(part.VertexBuffer);
                        GraphicsDevice.Indices = part.IndexBuffer; GraphicsDevice.DrawIndexedPrimitives(PrimitiveType.TriangleList, part.VertexOffset, part.StartIndex, part.PrimitiveCount);
                    }
                }
            }
        }

        //Draw Edge Map
        private void DrawEdgeMap()
        {
            effect.CurrentTechnique = effect.Techniques["EdgeMap"];

            foreach (EffectPass pass in effect.CurrentTechnique.Passes)
            {
                foreach (ModelMesh mesh in plane.Meshes)
                {
                    foreach (ModelMeshPart part in mesh.MeshParts)
                    {
                        effect.Parameters["World"].SetValue(mesh.ParentBone.Transform);
                        effect.Parameters["View"].SetValue(view);
                        effect.Parameters["Projection"].SetValue(projection);
                        Matrix worldInverseTransposeMatrix = Matrix.Transpose(Matrix.Invert(mesh.ParentBone.Transform));
                        effect.Parameters["WorldInverseTranspose"].SetValue(worldInverseTransposeMatrix);
                        effect.Parameters["dim"].SetValue(new Vector2(depthNormMap.Width, depthNormMap.Height));
                        effect.Parameters["depthAndNormalTex"].SetValue(depthNormMap);
                        effect.Parameters["EdgeSize"].SetValue(edgeSize);
                        effect.Parameters["red"].SetValue(red);
                        effect.Parameters["green"].SetValue(green);
                        effect.Parameters["blue"].SetValue(blue);
                        effect.Parameters["boldness"].SetValue(boldness);


                        pass.Apply();
                        GraphicsDevice.SetVertexBuffer(part.VertexBuffer);
                        GraphicsDevice.Indices = part.IndexBuffer;
                        GraphicsDevice.DrawIndexedPrimitives(PrimitiveType.TriangleList, part.VertexOffset, part.StartIndex, part.PrimitiveCount);
                    }
                }
            }

        }

        private void DrawSketchyDrawing()
        {
            effect = Content.Load<Effect>("EdgeMap");
            technique = 3;

            effect.CurrentTechnique = effect.Techniques["SketchyDrawing"];

            foreach (EffectPass pass in effect.CurrentTechnique.Passes)
            {
                foreach (ModelMesh mesh in plane.Meshes)
                {
                    foreach (ModelMeshPart part in mesh.MeshParts)
                    {
                        effect.Parameters["World"].SetValue(mesh.ParentBone.Transform);
                        effect.Parameters["View"].SetValue(view);
                        effect.Parameters["Projection"].SetValue(projection);
                        Matrix worldInverseTransposeMatrix = Matrix.Transpose(Matrix.Invert(mesh.ParentBone.Transform));
                        effect.Parameters["WorldInverseTranspose"].SetValue(worldInverseTransposeMatrix);
                        effect.Parameters["dim"].SetValue(new Vector2(depthNormMap.Width, depthNormMap.Height));
                        effect.Parameters["depthAndNormalTex"].SetValue(depthNormMap);
                        effect.Parameters["EdgeSize"].SetValue(edgeSize);
                        effect.Parameters["red"].SetValue(red);
                        effect.Parameters["green"].SetValue(green);
                        effect.Parameters["blue"].SetValue(blue);
                        effect.Parameters["boldness"].SetValue(boldness);

                        pass.Apply();
                        GraphicsDevice.SetVertexBuffer(part.VertexBuffer);
                        GraphicsDevice.Indices = part.IndexBuffer;
                        GraphicsDevice.DrawIndexedPrimitives(PrimitiveType.TriangleList, part.VertexOffset, part.StartIndex, part.PrimitiveCount);
                    }
                }
            }
        }

    }
}
