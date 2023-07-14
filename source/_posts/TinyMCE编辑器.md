---
title: TinyMCE编辑器
date: 2023-07-14 11:29:48
updated: 2023-07-14 11:29:48
tags: [富文本编辑器,TinyMCE]
categories: 开发工具
---

### TinyMCE
- TinyMCE是一款易用、且功能强大的所见即所得的富文本编辑器。同类程序有：UEditor、Kindeditor、Simditor、CKEditor、wangEditor、Suneditor、froala等等
- TinyMCE的优势：
    - 开源可商用，基于LGPL2.1
    - 插件丰富，自带插件基本涵盖日常所需功能（示例看下面的Demo-2）
    - 接口丰富，可扩展性强，有能力可以无限拓展功能
    - 界面好看，符合现代审美
    - 提供经典、内联、沉浸无干扰三种模式（详见“介绍与入门”）
    - 对标准支持优秀（自v5开始）
    - 多语言支持，官网可下载几十种语言

#### 1、快速开始
- [中文文档：http://tinymce.ax-z.cn/](http://tinymce.ax-z.cn/)
- [Github地址:https://github.com/tinymce/tinymce](https://github.com/tinymce/tinymce)
- 下载：[https://www.tiny.cloud/get-tiny/self-hosted/](https://www.tiny.cloud/get-tiny/self-hosted/)
- 引入js源文件：`<script src="你的网站路径/tinymce/tinymce.min.js"></script>`
- Demo如下：

```html
<!DOCTYPE html>
<html>
<head>
  <script src='tinymce.min.js'></script>
  <script>
  tinymce.init({
        selector: '#mytextarea',
        language: 'zh_CN',//注意大小写
        // plugins: 'image link autolink code table preview codesample emoticons fullscreen lists advlist media pagebreak searchreplace',
        plugins: 'preview searchreplace autolink directionality visualblocks visualchars fullscreen image link media template code codesample table charmap  pagebreak nonbreaking anchor insertdatetime advlist lists wordcount  help emoticons autosave  autoresize',
        toolbar: 'code undo redo restoredraft | cut copy paste pastetext | forecolor backcolor bold italic underline strikethrough link anchor | alignleft aligncenter alignright alignjustify outdent indent | \
    styleselect formatselect fontselect fontsizeselect | bullist numlist | blockquote subscript superscript removeformat | \
    table image media charmap emoticons pagebreak insertdatetime preview | fullscreen |  lineheight ',
        images_upload_url: '/upload/tinyImage',
        images_upload_base_path: '',
        max_height: 750,
        fontsize_formats: '12px 14px 16px 18px 24px 36px 48px 56px 72px',
        font_formats: '微软雅黑=Microsoft YaHei,Helvetica Neue,PingFang SC,sans-serif;苹果苹方=PingFang SC,Microsoft YaHei,sans-serif;宋体=simsun,serif;仿宋体=FangSong,serif;黑体=SimHei,sans-serif;Arial=arial,helvetica,sans-serif;Arial Black=arial black,avant garde;Book Antiqua=book antiqua,palatino;',
        toolbar_sticky: true,
        autosave_ask_before_unload: false,
        file_picker_callback: function (callback, value, meta) {
            //文件分类
            let filetype = '.pdf, .txt, .zip, .rar, .7z, .doc, .docx, .xls, .xlsx, .ppt, .pptx, .mp3, .mp4';
            //后端接收上传文件的地址
            let upurl = '/upload/tinyFile';
            //为不同插件指定文件类型及后端地址
            switch (meta.filetype) {
                case 'image':
                    filetype = '.jpg, .jpeg, .png, .gif';
                    break;
                case 'media':
                    filetype = '.mp3, .mp4';
                    break;
                case 'file':
                default:
            }
            //模拟出一个input用于添加本地文件
            let input = document.createElement('input');
            input.setAttribute('type', 'file');
            input.setAttribute('accept', filetype);
            input.click();
            input.onchange = function () {
                let file = this.files[0];

                let xhr, formData;
                console.log(file.name);
                xhr = new XMLHttpRequest();
                xhr.withCredentials = false;
                xhr.open('POST', upurl);
                xhr.onload = function () {
                    let json;
                    if (xhr.status != 200) {
                        failure('HTTP Error: ' + xhr.status);
                        return;
                    }
                    json = JSON.parse(xhr.responseText);
                    if (!json || typeof json.location != 'string') {
                        failure('Invalid JSON: ' + xhr.responseText);
                        return;
                    }
                    callback(json.location);
                };
                formData = new FormData();
                formData.append('file', file, file.name);
                xhr.send(formData);
            }
        }
    });
      
      // 获取tinymce内容
      let content = tinymce.activeEditor.getContent();
  </script>
</head>

<body>
<h1>TinyMCE快速开始示例</h1>
  <form method="post">
    <textarea id="mytextarea">Hello, World!</textarea>
  </form>
</body>
</html>

```

- 如上包含了常用的一些标签，上传图片与文件后端代码示例：

```java
@PostMapping(value = {"/tinyImage","tinyFile"})
    @ResponseBody
    public Object tinyImage(@RequestParam(value = "file") MultipartFile file){
        if (file.isEmpty()) {
            throw new ApiException(ApiResultEnum.FILE_IS_NULL,null);
        }
        // 获取文件名
        String fileName = file.getOriginalFilename();
        String suffixName = fileName.substring(fileName.lastIndexOf("."));
        String folder = "/"+ DateUtil.getDays()+"/";
        fileName  = System.currentTimeMillis()+suffixName;
        File dest = ImgUtil.createFile(PathsUtils.getAbsolutePath(rootPath+folder+fileName));
        try {
            file.transferTo(dest);
        }catch (IOException e) {
            logger.error(e.getMessage(),e);
            throw new ApiException(ApiResultEnum.ERROR_IO);
        }
        Map<String,String> data = new HashMap<>();
//        data.put("location",prePath+folder+fileName);
        data.put("location","/show"+folder+fileName);
        return data;
    }
```

- 更多内容，直接看文档即可：[TinyMCE中文文档中文手册](http://tinymce.ax-z.cn/)
