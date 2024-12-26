# [am-serv00-vmess](https://github.com/amclubs/am-serv00-vmess)
这个项目的脚本安装管理并运行一个VMess节点,并可以通过Cloudflare的CDN设置域名回源进行加速,解锁ChatGPT、TikTok、其它流媒体、小网站等

#
▶️ **新人[YouTube](https://youtube.com/@AM_CLUB)** 需要您的支持，请务必帮我**点赞**、**关注**、**打开小铃铛**，***十分感谢！！！*** ✅
</br>🎁 在Fork项目时,请 **follow** 我的GitHub、给我所有项目一个 **Star** 星星支持下！你的支持是我不断前进的动力！ 💖
</br>✅**解锁更多技术请点击进入 YouTube频道[【@AM_CLUB】](https://youtube.com/@AM_CLUB) 、[【个人博客】](https://am.809098.xyz)** 、TG群[【AM科技 | 分享交流群】](https://t.me/AM_CLUBS) 、获取免费节点[【进群发送关键字: 订阅】](https://t.me/AM_CLUBS)


# 免费serv00服务器一键脚本部署VMess

- [视频教程](https://youtu.be/6UZXHfc3zEU)
- [青龙保活教程](https://youtu.be/J4lcIwBowmM)
- [GitHub Actions保活教程](https://youtu.be/zkGGklEaO2I)

# 部署教程：

## 一、需要准备的前提资料
### 1、首先注册一个Serv00账号，建议使用gmail邮箱注册，注册好会有一封邮箱上面写着你注册时的用户名和密码
- 注册帐号地址：https://serv00.com
<center>注册帐号请查看下面视频</center>
<center><a href="https://youtu.be/NET1FTlfDTs">[点击观看视频教程]</a></center>

![image](https://github.com/user-attachments/assets/57c3ff7b-ae42-42c0-87ac-acb1b5bd177a)

### 2、加下群发送关键字 ssh 获取连接工具
Telegram频道：[@AM_CLUBS](https://t.me/AM_CLUBS)

## 二、安装前需准备的初始设置
- 1、登入邮件里面发你的 DevilWEB webpanel 后面的网址，进入网站后点击 Change languag 把面板改成英文
- 2、然后在左边栏点击 Additonal services ,接着点击 Run your own applications 看到一个 Enable 点击
- 3、找到 Port reservation 点击后面的 Add Port 新开一个端口，随便写，也可以点击 Port后面的 Random随机选择Port tybe 选择 TCP
- 4、然后点击 Port list 你会看到一个端口
![image](https://github.com/user-attachments/assets/1b11ebdb-49e6-427d-a074-f51d52235f7e)


- 5、 启用管理权限：
<img width="800" height="600" alt="serv00" src="https://github.com/user-attachments/assets/48466f3a-1b75-4cf3-8dd9-7c2e440b73fe">

***完成此步骤后，退出 SSH 并再次登录。***

## 三、开始安装部署

- 1、用我们前面下载的工具登入SSH(有些工具 第一次连接还是会弹出输出密码记得点X 然后再添加密码 )
使用 serv00 通过电子邮件发送给您的信息（下面username、panel要修改成你邮箱收到对应的信息）。
```
ssh <username>@<panel>.serv00.com
```

- 2、vmess、Cloudflare隧道Argo+CDN回源节点 一键安装 
```
bash <(curl -Ls https://raw.githubusercontent.com/amclubs/am-serv00-vmess/main/install_serv00_vmess.sh)
```
- 指定UUID安装(<UUID> 要换成你要生成的UUID) [在线获取UUID](https://1024tools.com/uuid) 
```
bash <(curl -Ls https://raw.githubusercontent.com/amclubs/am-serv00-vmess/main/install_serv00_vmess.sh <UUID>)
```
- 例如:
```
bash <(curl -Ls https://raw.githubusercontent.com/amclubs/am-serv00-vmess/main/install_serv00_vmess.sh df4abc6a-5a79-4104-93c9-250756008e9b)
```

- 3、vless(reality)、vmess、hysteria2三协议节点 、Cloudflare隧道Argo+CDN回源节点 一键安装 
```
bash <(curl -Ls https://raw.githubusercontent.com/amclubs/am-serv00-vmess/main/install_serv00_vless_vmess_hysteria2.sh)
```

- 4、保活教程
- [青龙保活教程](https://youtu.be/J4lcIwBowmM)
- [GitHub Actions保活教程](https://youtu.be/zkGGklEaO2I)

## 四、测试节点
- 1、把安装成功返回的节点信息复制到订阅工具里就可以使用

- 2、如果不记得节点配置，可以通过下面信息查看
```
cat /home/${USER}/.vmess/list.txt
```
- 3、节点通过Cloudflare的CDN设置域名回源进行加速
- CF端口类型

HTTP：80，8080，8880，2052，2082，2086，2095

HTTPS：443，2053，2083，2087，2096，8443

- 4、请查看视频教程（Cloudflare的CDN设置域名回源进行加速） [视频教程](https://youtu.be/6UZXHfc3zEU)
- 5、[免费域名注册教程](https://youtu.be/cI36vtXuQrM)

## 五、卸载VMess
### 一键卸载命令，根据提示，选择2（2. 卸载sing-box） 直接卸载完成
```
bash <(curl -Ls https://raw.githubusercontent.com/amclubs/am-serv00-vmess/main/install_serv00_vmess.sh)
```


# 
 <center><details><summary><strong> [点击展开] 赞赏支持 ~🧧</strong></summary>
 *我非常感谢您的赞赏和支持，它们将极大地激励我继续创新，持续产生有价值的工作。*
  
 - **USDT-TRC20:** `TWTxUyay6QJN3K4fs4kvJTT8Zfa2mWTwDD`
  
 </details></center>

#
 免责声明:
 - 1、该项目设计和开发仅供学习、研究和安全测试目的。请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
 - 2、使用本程序必循遵守部署服务器所在地区的法律、所在国家和用户所在国家的法律法规。对任何人或团体使用该项目时产生的任何后果由使用者承担。
 - 3、作者不对使用该项目可能引起的任何直接或间接损害负责。作者保留随时更新本免责声明的权利，且不另行通知。
 
 

