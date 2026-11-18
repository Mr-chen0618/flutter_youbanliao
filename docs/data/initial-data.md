# 初始化数据导入

当前来源：`/Users/tabier/Downloads/应用数据-11:9/搭子App模拟数据.xlsx`及同目录`assets/`，导入日期2026-11-10。

已替换打包样本：用户20、活动24、动态20、兴趣/标签60，配套图片172，全部172个引用文件均已校验。用户详情使用表格中的三张相册图；活动使用三张活动图和活动头像。素材来源工作表保留为输入来源，不作为业务列表。

字段约定：保留用户/活动/动态ID与作者关系；用户分类categoryIds由该用户发布活动的类型去重生成，表格未提供独立的用户分类字段。发布时间原样保留，不视为活动排期；性别限制写入gender字段。缺少报名/聊天/履约数据时不新建虚构记录。既有有效动态活动关联按原ID保留，不根据文字新猜关联。

公共用户目录包含U001在内的全部用户，首页按实际登录ID排除本人。公共初始动态无固定本人标记，首次建立账号快照时按authorId判断isMine。提审号预注册逻辑不变，仍无预置的个人报名和发布记录。

重导入命令：

```sh
python3 tool/import_mock_workbook.py --source '/Users/tabier/Downloads/应用数据-11:9'
```

导入只修改工程内assets/mock及图片，不访问或覆盖手机已有账号快照。公开目录与兴趣读取新的打包数据；已写入手机的动态快照和用户编辑保留，新的账号快照使用新样本。原始文件未修改。导入清单和源文件哈希见import-2026-11-10.json。

## 2026-11-17 登录注销冷静期增量

按本次用户要求实现Figma7503恢复账号交互，auth/accounts新增可选pendingDeletions，键为稳定accountId，值为requestedAt和deadline两个ISO8601时间，默认7天。旧文件缺此字段按空集合兼容；原账号、目录和公开关联ID继续使用原身份。申请时只允许当前登录账号，重复申请保留原时间，auth/session置空。

冷静期登录通过验证码后返回受限结果，不先创建有效业务会话。选择恢复时绑定accountId/手机号/验证码，取消注销并将user/account的isDeleted清为false、isSignedIn设true，保留原资料和业务数据。到期后首次登录时幂等清理私有文件和本人公开活动，最后删除账号映射及pending，再分配新的递增ID。旧已永久删除账号保持删除，不复活。

auth/accounts另支持可选suspendedAccounts，键为手机号，值为reason和可选unblocksAt（ISO8601），用于认证返回的封禁说明。没有预置封禁数据。验证码时间与冷静期时间由AuthMockRepository可注入的now函数驱动，默认当前时间。此次无业务种子更改。上述均为磁盘Mock契约，真实短信和服务端定时清理仍待接入。

## 2026-11-18 内购权益边界

六个苹果商品均为消耗型。商品目录在 purchases 模块内，不更改初始种子或 Mock 账号余额。真实权益从 PurchaseFulfillmentRepository 获取并按 accountId 隔离展示；当前无后端实现，不伪造落账，默认禁用购买。服务端需要按 Apple 交易 ID 持久化幂等发放记录及 appAccountToken 账号归属。契约及剩余事项见 [苹果内购客户端](../ui-structure/apple-iap-2026-11-18.md)。

## 2026-11-18 苹果支付后端交接

[后端接入契约草案](apple-iap-backend-contract.md) 列明线上账号 token、验单发放、权益快照与通知建议接口。该文档不代表已实现服务，也未更改磁盘 Mock 数据；后端确认后再落实真实 HTTP 适配和持久化账本。

## 2026-11-18 本机支付账本

用户后续选择无业务后端方案。付费数据现存应用支持目录 purchases/apple_ledger.json（version=1），账号 UUID、环境分区余额/会员和交易去重原子提交，不改变初始样本或 Mock 资料快照。覆盖此前默认等后端开通的约定；数据字段、UTC 日历月规则、保留与恢复限制见 [本机支付](../ui-structure/apple-iap-local-2026-11-18.md)。
