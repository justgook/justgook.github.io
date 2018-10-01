# Introduction

# Build Your First Level

After this part You will know how build grid based 2D level.

Any part of game starts with data - so for our level we will take representation of grid - **two dimension array** which contains some tiles, think about as sheet of paper devided in cells, where each cell is game tile

For wall we will use `0` (red) and for empty cell `1` (blue)

Level is quite simple 3x3 tiles, where free cell is wrapped in walls.
<iframe-code src="/data/wizardry/level.html" lang="json">[
[1,1,1],
[1,0,1],
[1,1,1]
]</iframe-code>


But that is to borring lets make some maze

<iframe-code src="/data/wizardry/level.htm" lang="json">[
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1]
]</iframe-code>

So You have map - next step is add start and end point, for start `2` (yellow) and for end `3` (green)

<iframe-code src="/data/wizardry/level.htm" lang="json">[
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 2, 1, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 3, 1],
    [1, 1, 1, 1, 1, 1, 1, 1]
]</iframe-code>

Thats it Your firs leve is created, and it have all minimal requirements for game, start point, finish and some chalanges to solve (find the way out).

So time to make it move from paper to code, and it is much easier that You could imagine

Lets start with something simple - create one cell as `10`x`10` pixel red `div`

```javascript
const div = document.createElement('div');
div.style.width = '10px';
div.style.height = '10px';
div.style.backgroundColor = "red";
```



--MOVE OUTSIDE

```javascript
const level = [
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 2, 1, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 3, 1],
    [1, 1, 1, 1, 1, 1, 1, 1]
];
const ground = 0;
const wall = 1;
const start = 2;
const end = 3;
function cell(kind, x, y) {
  const div = document.createElement('div');
  div.style.position = 'absolute';
  div.style.width = '10px';
  div.style.height = '10px';
  div.style.left = `${x * 10}px`;
  div.style.top = `${y * 10}px`;
  switch (kind) {
    case wall:
      div.style.backgroundColor = "red"
      break;
    case start:
      div.style.backgroundColor = "yellow"
      break;
    case end:
      div.style.backgroundColor = "green"
      break;
    case ground:
    default:
      div.style.backgroundColor = "blue"
      break;
  }
  return div;
}
const renderable = level.reduce(
  (acc, row, y) =>
    row.reduce(
      (acc_, kind, x) =>
        (acc_.appendChild(cell(kind, x, y)), acc_)
    , acc)
, document.createElement('div'));
```

```javascript
const container = document.createElement('div');
for (let y = 0; y < level.length; y++) {
  for (let x = 0; x < level[y].length; x++) {
    container.appendChild(cell(level[y][x], x, y));
  }
}
```