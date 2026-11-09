'use strict';

// 注入站点自定义样式（页脚排版等）
const url_for = hexo.extend.helper.get('url_for').bind(hexo);

hexo.extend.injector.register('head_end', () => {
  return `<link rel="stylesheet" href="${url_for('/css/custom.css')}">`;
});
