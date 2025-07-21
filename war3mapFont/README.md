#### 引用 Font(字体)

* 字体使用后将自动改变UI字样，漂浮字需重启才生效

> 资源文件放在 assets/war3mapFont 里，格式支持：ttf

#### 引入字体配置

> 引入代码需放置在 your_project/assets/ 目录下，可参考new生成项目

```lua
assets_font("微软雅黑")
```

#### 对字体进行配置

> 字体可以进行属性配置，为同名的lua文件、如：霞鹜文楷（LXGWWenKai-Regular）.lua

```lua
-- 后面三个数字分别为：非中文宽度 中文宽度 字符高度
-- 配置的数字影响UI的显示
vistring.setFont("霞鹜文楷（LXGWWenKai-Regular）", 0.65, 1.02, 1.14)
```

#### Font的底层变量

> 使用assets_font引入字体后，该字体变量为 XLIK_FONT
>
> XLIK_FONT 在 vistring 中会被引用并调整其他相关的数据：如

```lua
local cr, zh = vistring.getFont(XLIK_FONT)
local _, _, fh = vistring.getFont(XLIK_FONT)
```

#### 字体配置数据的后续作用

> 字体进行属性配置后，在 vistring 中可被引用，如未配置，将使用默认数据

```lua
vistring.getFont(fontName)
-- 默认数据[创粗黑]
local cr = 0.65
local zh = 1.03
local h = 1.126
```
