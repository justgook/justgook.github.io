---
title: "Tilemaps as Lookup Textures"
date: 2026-04-26
description: "A compact note about drawing tilemaps by storing tile indices in a texture and resolving them in the shader."
tags: [rendering, tilemap, gpu, shader]
featured: false
---

## Tilemaps as Lookup Textures

A tilemap is usually easy to describe:

```text
| 2 2 2 |
| 0 1 0 |
| 0 1 0 |
````

This example can be read as a small T-shaped platform.

The numbers are not colors. They are tile references.

Given a tileset like this:

```text
| 1 2 3 |
| 4 5 6 |
| 7 8 9 |
```

the value `2` means “draw tile 2 here”, the value `1` means “draw tile 1 here”, and `0` means “draw nothing”.

That is the whole idea behind lookup-texture tilemaps: store the map as data, send that data to the GPU as a texture, and let the shader resolve which tile should appear at each position.

## Why draw it this way?

The direct way to render a tilemap is to draw every tile separately.

That works well for tiny maps. It is also easy to reason about.

But it does not scale very far.

A `100 x 100` map contains `10,000` tile cells. If each cell becomes its own renderable object, the renderer has to submit thousands of objects just to draw one layer of the map.

At that point the issue is not necessarily fill rate or pixel count.

The issue is how much work the CPU and renderer do to describe the scene every frame.

A lookup-texture tilemap changes the shape of the work:

```text
many tiles submitted by the CPU
```

becomes:

```text
one surface submitted by the CPU
tile selection done by the GPU
```

The map is still made of tiles, but it is no longer submitted as thousands of tile objects.

## Two textures

This technique uses two textures.

The first texture is the tileset.

```text
tileset texture = tile graphics
```

The second texture is the lookup table.

```text
lookup texture = tile indices
```

The lookup texture is like a tiny version of the map. Each pixel represents one tile cell.

A `100 x 100` tilemap can be represented by a `100 x 100` lookup texture.

Each lookup pixel stores a value that identifies which tile should be used at that cell.

```text
lookup pixel
-> tile index
-> tile position inside tileset
-> final sampled color
```

The lookup texture is not meant to be seen directly. It is a compact data source for the shader.

## Indexing

Tile index `0` is reserved for empty space.

Real tile indices start at `1`.

```text
0 = no tile
1 = first tile
2 = second tile
3 = third tile
...
```

Tiles are numbered left to right, top to bottom:

```text
| 1 2 3 |
| 4 5 6 |
| 7 8 9 |
```

To convert a tile index into a tileset grid position:

```text
zero_based = tile_index - 1

tile_x = zero_based % tileset_columns
tile_y = zero_based / tileset_columns
```

Then the shader uses that tile position plus the local pixel position inside the current tile to sample the tileset.

## What the shader does

For every fragment, the shader needs to answer two questions:

```text
Which tile cell am I inside?
Which pixel of that tile should I draw?
```

A typical flow looks like this:

```text
fragment position
-> position inside tilemap
-> tile cell coordinate
-> lookup texture sample
-> tile index
-> tileset tile coordinate
-> local coordinate inside tile
-> final tileset sample
```

In pseudocode:

```text
tile_position = floor(tilemap_position / tile_size)
tile_local    = fract(tilemap_position / tile_size)

tile_index = sample_lookup(tile_position)

if tile_index == 0:
    output transparent

tileset_position = index_to_tileset_position(tile_index)
tileset_uv = combine(tileset_position, tile_local)

output sample(tileset, tileset_uv)
```

Shader implementation placeholder:

```glsl
// TODO:
//
// - compute tilemap-local position
// - compute tile cell coordinate
// - sample lookup texture at the center of the lookup pixel
// - decode tile index
// - handle tile index 0
// - convert tile index to tileset grid coordinate
// - compute local UV inside selected tile
// - sample tileset
```

## Sampling the lookup texture

The lookup texture stores discrete values.

That means it must be sampled like data, not like an image.

The safest mental model is:

```text
sample the center of the lookup pixel
```

If the tile coordinate is `(x, y)`, the normalized lookup UV should be:

```text
lookup_uv.x = (x + 0.5) / lookup_width
lookup_uv.y = (y + 0.5) / lookup_height
```

or, more generally:

```text
lookup_uv = (floor(tile_coord) + 0.5) / lookup_texture_size
```

The `+ 0.5` moves the sample point to the center of the texel.

Without that, the shader may sample near an edge between two lookup pixels. That can cause the wrong tile index to be selected, especially when coordinates are interpolated, transformed, scaled, or affected by precision issues.

The lookup texture should normally use:

```text
nearest filtering
clamp-to-edge wrapping
no mipmaps
no color-space conversion, if the graphics API exposes that choice
```

Linear filtering is wrong for lookup data because it blends neighboring tile indices.

Mipmaps are also usually wrong because lower mip levels would contain averaged tile indices, which are not meaningful unless generated intentionally.

## Sampling the tileset

The lookup texture tells the shader which tile to use.

The tileset texture provides the pixels for that tile.

These are separate problems.

Even with perfect lookup sampling, the tileset can still show artifacts:

```text
bleeding from neighboring tiles
slightly wrong UVs
linear filtering
mipmaps
missing padding between tiles
floating-point precision
```

For pixel-art tilesets, nearest filtering is usually the simplest option.

For filtered tilesets, padding or gutters between tiles become important. Otherwise, sampling near the edge of one tile can pull color from the neighboring tile in the atlas.

Common fixes:

```text
add padding around each tile
disable mipmaps
generate padded mipmaps
clamp local tile UVs slightly inward
make tile boundaries align exactly to texels
```

## Empty cells

A lookup value of `0` means no tile.

There are two common ways to handle that:

```text
return transparent color
```

or:

```text
discard the fragment
```

Transparent output is often simpler and works well with ordinary 2D blending.

Discard can avoid writing pixels, but it may have different performance behavior depending on the GPU and pipeline.

This is an implementation choice.

## Encoding tile indices

The lookup texture needs to store tile indices somehow.

The simplest version stores the index in one channel:

```text
red channel = tile index
```

That gives up to 255 non-empty tile values if using an 8-bit channel and reserving `0` for empty.

Larger tilesets can use more data:

```text
red + green channels
rgba packing
integer textures
multiple lookup textures
```

The exact encoding depends on the renderer, shader language, texture formats, and target platforms.

A useful rule is: keep the lookup format boring until it is not enough.

## Updating the map

Changing the tilemap means changing the lookup texture.

That works well for:

```text
loading a level
editing a map
streaming chunks
occasional tile changes
```

It is less ideal if most of the map changes every frame.

For large or editable worlds, the map can be split into chunks:

```text
world
-> chunk
-> lookup texture
-> rendered surface
```

Then only changed chunks need to upload new lookup data, and only visible chunks need to be drawn.

This keeps the technique useful without forcing the entire world into one giant texture.

## Where this works well

Lookup-texture tilemaps are a good fit when:

```text
tiles are grid-aligned
tile size is fixed
the map is large
the map is mostly static
the visual result can be resolved in a shader
```

They are especially useful for background layers, terrain layers, platform maps, editor previews, collision/debug overlays, and any place where thousands of repeated tile objects would otherwise be submitted every frame.

## Where it gets awkward

This is not a replacement for sprites or entities.

It is less useful for things that need independent transforms or behavior:

```text
moving platforms
characters
particles
individually animated objects
tiles with complex per-instance state
```

Those can still exist on top of the tilemap. The tilemap technique is mainly about moving the static, regular part of the scene into a compact GPU-friendly representation.

## The useful distinction

The important distinction is this:

```text
tileset = image
lookup texture = data
```

The tileset is sampled for color.

The lookup texture is sampled for meaning.

Once that distinction is clear, most of the implementation details follow from it:

```text
sample lookup pixels exactly
do not filter lookup data
reserve 0 for empty cells
convert indices into tileset coordinates
watch out for atlas bleeding
chunk large or dynamic maps
```

This keeps the renderer from thinking in terms of thousands of tile objects, while still keeping the map easy to author, inspect, generate, and serialize.

## References

* [Sprite tile maps on the GPU][tojicode]
* [LearnOpenGL: Texture filtering][learnopengl-textures]
* [Understanding Half-Pixel and Half-Texel Offsets][half-texel]

[tojicode]: https://blog.tojicode.com/2012/07/sprite-tile-maps-on-gpu.html
[learnopengl-textures]: https://learnopengl.com/Getting-started/Textures
[half-texel]: https://www.drilian.com/posts/2008.11.24-understanding-half-pixel-and-half-texel-offsets/

