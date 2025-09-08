using UnityEngine;
using UnityEngine.UI;

public class Showcase : MonoBehaviour
{
    [SerializeField] 
    private TextureShowcase[] showcases;
    
    public void ToggleShow()
    {
        gameObject.SetActive(!gameObject.activeSelf);
    }

    public void ChangeShowcase(int index, string title, Texture2D texture)
    {
        ChangeShowcaseImage(index, texture);    
        ChangeShowcaseTitle(index, title);    
    }

    public void ChangeShowcaseImage(int index, Texture2D texture)
    {
        showcases[index].SetTextureAsImage(texture);
    }
    
    public void ChangeShowcaseTitle(int index, string title)
    {
        showcases[index].SetTitle(title);
    }
}
