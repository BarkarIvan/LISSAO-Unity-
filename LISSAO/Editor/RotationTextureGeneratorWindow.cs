using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class RotationTextureGeneratorWindow : EditorWindow
{
    
    int numSteps = 16;            
    float angleStart = 0f;       
    float angleEnd = 180f;       
    float jitterAmp = 10f;       
    int seed = 0;                

    [MenuItem("Tools/Rotation Texture Generator")]
    public static void ShowWindow()
    {
        GetWindow<RotationTextureGeneratorWindow>("Rotation Texture Generator");
    }

    void OnGUI()
    {
        GUILayout.Space(20f);
        numSteps = EditorGUILayout.IntField("numSteps", numSteps);
        angleStart = EditorGUILayout.FloatField("angleStart", angleStart);
        angleEnd = EditorGUILayout.FloatField("angleEnd", angleEnd);
        jitterAmp = EditorGUILayout.FloatField("jitterAmp", jitterAmp);
        seed = EditorGUILayout.IntField("seed", seed);

        GUILayout.Space(20f);
        if (GUILayout.Button("Generate"))
        {
            GenerateRotationTexture();
        }
    }

    void GenerateRotationTexture()
    {
        const int textureSize = 4; 
        Texture2D texture = new Texture2D(textureSize, textureSize, TextureFormat.RGHalf, false);
        texture.filterMode = FilterMode.Bilinear;
        texture.wrapMode = TextureWrapMode.Repeat;

        
        List<Vector2> rotationValues = new List<Vector2>(); // x = sin, y = cos
        float range = angleEnd - angleStart;
        float step = (numSteps > 1) ? range / (numSteps - 1) : 0f;

        for (int i = 0; i < numSteps; i++)
        {
            float baseAngle = angleStart + step * i;
         
            float r = Rand(new Vector3(i, seed * 123.45f, 0.789f));
           
            float offset = Mathf.Lerp(-jitterAmp, jitterAmp, r);
            float jitteredAngle = baseAngle + offset;
         
            float radAngle = jitteredAngle * Mathf.Deg2Rad;
            float sinVal = Mathf.Sin(radAngle);
            float cosVal = Mathf.Cos(radAngle);
            rotationValues.Add(new Vector2(sinVal, cosVal));
        }

        
        int totalPixels = textureSize * textureSize;
        for (int i = 0; i < totalPixels; i++)
        {
            Vector2 sinCos = rotationValues[i % rotationValues.Count];
            Color pixelColor = new Color(sinCos.x, sinCos.y, 0f, 1f);
            int x = i % textureSize;
            int y = i / textureSize;
            texture.SetPixel(x, y, pixelColor);
        }
        texture.Apply();

       
        string path = EditorUtility.SaveFilePanelInProject("Сохранить текстуру", "RotationTexture", "asset", "Укажите путь для сохранения текстуры");
        if (!string.IsNullOrEmpty(path))
        {
            AssetDatabase.CreateAsset(texture, path);
            AssetDatabase.SaveAssets();
            EditorUtility.DisplayDialog("Готово", "Текстура успешно сгенерирована и сохранена по пути:\n" + path, "OK");
        }
    }


    float Rand(Vector3 v)
    {
        float dot = Vector3.Dot(v, new Vector3(12.9898f, 78.233f, 37.719f));
        float sinValue = Mathf.Sin(dot) * 43758.5453f;
        return sinValue - Mathf.Floor(sinValue);
    }
}
