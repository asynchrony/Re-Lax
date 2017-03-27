# ReLax

<p align="center">
  <img src="demo.gif" width="640" height="360" />
</p>

## Programmatic Effect

**ReLax** makes creating programmatic parallax effects super simple:

```swift
let parallaxView = ParallaxView(images: images)
```

## LCR

LCR files are most useful when creating Top Shelf extensions that display parallax content. If your app retrieves layered images from a server at runtime, you must provide those images as `LCR` files. `LCR` files are generated from `.lsr` or Photoshop files using the `layerutil` command-line tool that’s installed with Xcode, or by using `ParallaxPreviewer.app`. This process does not scale when creating parallax files for dynamic content; fortunately, ReLax fixes this.

**ReLax** has reverse engineered the `LCR` image format in order to make this convenient for content providers. This can be done _on the fly_ without the need to use a server to distribute the parallax image files. ReLax makes programmatically generating `LCR` files within your app or extension a breeze:

```swift
let parallaxImage = ParallaxImage(images: images)
let lcrImage: UIImage = parallaxImage.image()
```
