---
name: apache-echarts-data-visualization
type: design-pattern
role: design
tags: [design, data-visualization, charts, apache-echarts, ui]
related:
  - ../tokens/aura-design-tokens.md
status: active
owner: design-team
updated: 2026-04-24
source: https://echarts.apache.org/en/
---

# Apache ECharts Data Visualization

## Purpose
Reusable reference for designing and implementing chart-heavy UI with Apache ECharts. Use this when a designer is creating a new dashboard, report, analytics view, chart component, or updating an existing data visualization.

## When to use
- Product UI needs line, bar, pie, scatter, map, tree, treemap, sankey, gauge, funnel, heatmap, or other interactive chart patterns.
- Design needs to validate chart feasibility before handoff to engineering.
- Dev needs implementation guidance for ECharts wrappers, rendering mode, theming, responsiveness, events, or large data.

## Usage guidance
- Prefer Canvas for large datasets, heatmaps, and animation-heavy charts.
- Prefer SVG for smaller charts where accessibility, export quality, or CSS styling is more important.
- Define empty, loading, error, and no-data states in the design.
- Keep colors aligned to [Aura Design Tokens](../tokens/aura-design-tokens.md).
- Include tooltip, legend, axis, data zoom, and responsive behavior in design handoff when relevant.
- For accessibility, provide text summaries or tabular alternatives for critical chart data.

## Source artifacts
- Apache ECharts docs: https://echarts.apache.org/en/
- Examples: https://echarts.apache.org/examples/
- Option reference: https://echarts.apache.org/en/option.html
- GitHub: https://github.com/apache/echarts

## Related work
- [Aura Design Tokens](../tokens/aura-design-tokens.md)

## Open questions / known gaps
- Project-specific chart theme mapping is not yet documented.
- Approved chart color palettes for semantic states should be finalized from Aura tokens.

---

# Apache ECharts Skill

Apache ECharts is a free, powerful charting and visualization library for browsers, written in
pure JavaScript and based on ZRender (a lightweight canvas/SVG abstraction layer). It supports
20+ chart types, handles millions of data points efficiently, and has a rich ecosystem of
extensions and framework wrappers.

**Official resources:**
- Docs: https://echarts.apache.org/en/
- Examples: https://echarts.apache.org/examples/
- Option reference: https://echarts.apache.org/en/option.html
- GitHub: https://github.com/apache/echarts

---

## Quick Start (Vanilla JS)

```html
<div id="chart" style="width:600px;height:400px;"></div>
<script src="https://cdn.jsdelivr.net/npm/echarts/dist/echarts.min.js"></script>
<script>
  const chart = echarts.init(document.getElementById('chart'));
  chart.setOption({
    xAxis: { type: 'category', data: ['Mon','Tue','Wed','Thu','Fri'] },
    yAxis: { type: 'value' },
    series: [{ type: 'bar', data: [120, 200, 150, 80, 70] }]
  });
</script>
```

**Install via npm:**
```bash
npm install echarts
```

```js
import * as echarts from 'echarts';
// or tree-shakeable:
import { init, use } from 'echarts/core';
import { BarChart } from 'echarts/charts';
import { GridComponent } from 'echarts/components';
import { CanvasRenderer } from 'echarts/renderers';
use([BarChart, GridComponent, CanvasRenderer]);
```

---

## Renderer Selection

ECharts supports both Canvas and SVG rendering — switch with a flag:

```js
echarts.init(dom, null, { renderer: 'svg' }); // or 'canvas' (default)
```

- **Canvas** — recommended for large datasets (>1,000 data points), animations, heatmaps.
- **SVG** — better for low-end Android devices, high-resolution export, CSS styling, accessibility.

---

## Chart Types (20+)

| Category | Types |
|---|---|
| Basic | `line`, `bar`, `pie`, `scatter` |
| Statistical | `boxplot`, `candlestick`, `effectScatter` |
| Geographic | `map`, `heatmap`, `lines` |
| Relational | `graph`, `tree`, `treemap`, `sunburst`, `sankey` |
| Advanced | `parallel`, `radar`, `gauge`, `funnel`, `themeRiver` |
| Custom | `custom` (fully programmable render function) |

**3D / GL** (via `echarts-gl`): `bar3D`, `scatter3D`, `surface`, `lines3D`, `map3D`, `globe`.

---

## Framework Integrations

### React

**Recommended: `echarts-for-react`**
```bash
npm install echarts-for-react echarts
```
```jsx
import ReactECharts from 'echarts-for-react';
export default () => (
  <ReactECharts option={{ xAxis:{type:'category',data:['A','B','C']},
    yAxis:{type:'value'}, series:[{type:'bar',data:[10,20,30]}] }} />
);
```
- Repo: https://git.hust.cc/echarts-for-react/
- Alternative: `ECharts-JSX` — real JSX/TypeScript/Web Components wrapper

### Vue

**Recommended: `vue-echarts` (official, by Justineo/ecomfe)**
```bash
npm install vue-echarts echarts
```
```vue
<template>
  <v-chart :option="option" style="height:400px" />
</template>
<script setup>
import VChart from 'vue-echarts';
import { ref } from 'vue';
const option = ref({ series: [{ type: 'pie', data: [{value:40,name:'A'}] }] });
</script>
```
- Docs: https://vue-echarts.dev/
- Supports Vue 2 & Vue 3

### Angular

**Recommended: `ngx-echarts`**
```bash
npm install ngx-echarts echarts
```
```typescript
// app.module.ts
import { NgxEchartsModule } from 'ngx-echarts';
@NgModule({ imports: [NgxEchartsModule.forRoot({ echarts })] })

// component.html
<div echarts [options]="chartOption" style="height:400px"></div>
```
- Docs: https://xieziyu.github.io/ngx-echarts
- Alternative: `echarts-for-angular` (Angular ≥ 5.x directive)

### Svelte

**`svelte-echarts`**
```bash
npm install svelte-echarts echarts
```
```svelte
<script>
  import { ECharts } from 'svelte-echarts';
  const option = { series: [{ type: 'line', data: [1,2,3] }] };
</script>
<ECharts {option} />
```

### React Native

| Library | Notes |
|---|---|
| `wrn-echarts` (by @wuba) | Uses react-native-svg + react-native-skia; best performance |
| `react-native-echarts-pro` | Full chart + map support |
| `react-native-echarts-wrapper` | WebView-based |

---

## Official Extensions

```bash
npm install echarts-gl        # 3D plots, globe, WebGL acceleration
npm install echarts-wordcloud # Word cloud (wordcloud2.js based)
npm install echarts-liquidfill # Liquid fill / water ball gauge
```

### ECharts GL (3D)
```js
import * as echarts from 'echarts';
import 'echarts-gl';
chart.setOption({ globe: {}, series: [{ type: 'scatter3D', ... }] });
```
- ECharts GL 2.x → compatible with ECharts 5.x
- ECharts GL 1.x → compatible with ECharts 4.x

---

## Map Extensions

| Extension | Description |
|---|---|
| `echarts-extension-gmap` | Google Maps integration |
| `echarts-leaflet` | Leaflet.js overlay |
| `echarts-china-cities-js` | 363 Chinese city maps |
| `maptalks.e3` | maptalks.js layer |
| `openlayers-echarts3` | OpenLayers 3/4 integration |

---

## Other Language Bindings

| Language | Library |
|---|---|
| Python | `pyecharts` (most popular), `pyecharts.js`, `echarts-python`, `krisk` (Jupyter) |
| Jupyter | `ipecharts`, `jupyter-echarts` |
| Go | `go-echarts` |
| Java | `ECharts Java` (v5.x), `ECharts-Java` |
| R | `echarts4r`, `recharts` |
| PHP | `Echarts-PHP` |
| .NET / Blazor | `EChartsSDK`, `TagEChartsBlazor` |
| Flutter | `flutter_echarts` |
| Ruby | `rails_charts` |
| Julia | `ECharts.jl` |

---

## Theming

```js
// Use a built-in theme
echarts.init(dom, 'dark');

// Register a custom theme
echarts.registerTheme('myTheme', { color: ['#c23531','#2f4554'] });
echarts.init(dom, 'myTheme');
```

Theme builder: https://echarts.apache.org/en/theme-builder.html

---

## Performance Tips for Large Datasets

1. Use `Canvas` renderer for >1,000 data points.
2. Enable `large: true` on series for scatter/line with huge data.
3. Use `sampling: 'lttb'` (Largest-Triangle-Three-Buckets) on line charts.
4. `progressive` rendering for gradual display.
5. Disable animations: `animation: false`.
6. Use `dataset` with transforms instead of pre-processing in JS.

```js
series: [{
  type: 'scatter',
  large: true,
  largeThreshold: 2000,
  data: hugeDataArray
}]
```

---

## Common Patterns

### Responsive resize
```js
window.addEventListener('resize', () => chart.resize());
```

### Update data without full re-render
```js
chart.setOption({ series: [{ data: newData }] }, { notMerge: false });
```

### Event handling
```js
chart.on('click', 'series', (params) => {
  console.log(params.data, params.seriesName);
});
```

### Tooltip formatter
```js
tooltip: {
  formatter: (params) => `${params.name}: <b>${params.value}</b>`
}
```

### dataZoom (pan & zoom)
```js
dataZoom: [
  { type: 'inside', start: 0, end: 50 },
  { type: 'slider' }
]
```

---

## Dev Tools

- **echarts-vscode-extension** — VS Code autocompletion for ECharts options
- **echarts-scrappeteer** — Puppeteer scraper for ECharts instances on a page

---

## Ecosystem Notes

- Items marked 🇨🇳 in awesome-echarts are Chinese-language resources.
- For Angular: prefer `ngx-echarts` (actively maintained, Angular ≥ 2.x) over the older `angular-echarts` (AngularJS).
- For Vue: `vue-echarts` by Justineo is the canonical library and is maintained under the ecomfe GitHub org.
- For Python dashboards: `pyecharts` is by far the most comprehensive and actively maintained option.
- `echarts-stat` (official) provides statistical transforms: regression, clustering, histogram.

