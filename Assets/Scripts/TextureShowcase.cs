using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class TextureShowcase : MonoBehaviour
{
    public Image image;
    public TextMeshProUGUI text;
    
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Awake()
    {
    }

    public void SetTitle(string title)
    {
        text.text = title;
    }

    public void SetTextureAsImage(Texture2D texture)
    {
        image.sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), Vector2.zero);
    }
}
