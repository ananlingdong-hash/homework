-- ============================================================
-- 淘宝网数据库 ER 图 (中文表名/字段名，教学用)
-- ============================================================

-- 1. 用户表
CREATE TABLE 用户 (
    用户ID INT PRIMARY KEY COMMENT '用户唯一标识',
    用户名 VARCHAR(50) NOT NULL COMMENT '登录用户名',
    密码 VARCHAR(255) NOT NULL COMMENT '加密后的密码',
    手机号 VARCHAR(20) NOT NULL COMMENT '注册手机号',
    注册时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '账号注册时间'
) COMMENT '平台所有用户账号信息';

-- 2. 角色表 (商家、客户等)
CREATE TABLE 角色 (
    角色ID INT PRIMARY KEY COMMENT '角色唯一标识',
    角色名称 VARCHAR(20) NOT NULL COMMENT '角色名，如：商家、客户'
) COMMENT '用户权限角色定义';

-- 3. 用户-角色 关联表 (多对多)
CREATE TABLE 用户角色关系 (
    用户ID INT COMMENT '引用用户表',
    角色ID INT COMMENT '引用角色表',
    PRIMARY KEY (用户ID, 角色ID),
    FOREIGN KEY (用户ID) REFERENCES 用户(用户ID) ON DELETE CASCADE,
    FOREIGN KEY (角色ID) REFERENCES 角色(角色ID) ON DELETE CASCADE
) COMMENT '一个用户可拥有多个角色（如既是商家又是客户）';

-- 4. 店铺表 (商家拥有)
CREATE TABLE 店铺 (
    店铺ID INT PRIMARY KEY COMMENT '店铺唯一标识',
    店铺名称 VARCHAR(100) NOT NULL COMMENT '店铺展示名称',
    商家ID INT NOT NULL COMMENT '店主(用户ID)',
    创建时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '开店时间',
    店铺评分 DECIMAL(3,2) DEFAULT 5.0 COMMENT '店铺综合评分，范围0-5',
    FOREIGN KEY (商家ID) REFERENCES 用户(用户ID)
) COMMENT '商家经营的店铺信息';

-- 5. 商品分类表 (支持多级分类，父分类ID自关联)
CREATE TABLE 商品分类 (
    分类ID INT PRIMARY KEY COMMENT '分类唯一标识',
    分类名称 VARCHAR(50) NOT NULL COMMENT '分类名称，如：女装、手机',
    父分类ID INT DEFAULT NULL COMMENT '上级分类ID，NULL表示一级分类',
    FOREIGN KEY (父分类ID) REFERENCES 商品分类(分类ID)
) COMMENT '商品所属的层级分类，支持无限级';

-- 6. 商品表
CREATE TABLE 商品 (
    商品ID INT PRIMARY KEY COMMENT '商品唯一标识',
    商品名称 VARCHAR(200) NOT NULL COMMENT '商品标题',
    介绍 TEXT COMMENT '商品详细介绍（富文本）',
    价格 DECIMAL(10,2) NOT NULL COMMENT '商品销售基准价',
    库存 INT NOT NULL DEFAULT 0 COMMENT '商品总库存（不考虑规格时）',
    上架时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    商家ID INT NOT NULL COMMENT '发布商品的商家(用户ID)',
    店铺ID INT NOT NULL COMMENT '所属店铺',
    分类ID INT NOT NULL COMMENT '所属叶子分类',
    FOREIGN KEY (商家ID) REFERENCES 用户(用户ID),
    FOREIGN KEY (店铺ID) REFERENCES 店铺(店铺ID),
    FOREIGN KEY (分类ID) REFERENCES 商品分类(分类ID)
) COMMENT '商品主表，记录商品基本信息';

-- 7. 商品图片表 (一对多)
CREATE TABLE 商品图片 (
    图片ID INT PRIMARY KEY COMMENT '图片唯一标识',
    商品ID INT NOT NULL COMMENT '所属商品',
    图片URL VARCHAR(255) NOT NULL COMMENT '图片存储地址',
    排序号 INT DEFAULT 0 COMMENT '展示顺序，越小越靠前',
    FOREIGN KEY (商品ID) REFERENCES 商品(商品ID) ON DELETE CASCADE
) COMMENT '商品的展示图片，支持多张';

-- 8. 商品规格表 (SKU)
CREATE TABLE 商品规格 (
    规格ID INT PRIMARY KEY COMMENT '规格唯一标识',
    商品ID INT NOT NULL COMMENT '所属商品',
    规格名称 VARCHAR(50) NOT NULL COMMENT '规格描述，如：红色 / XL',
    规格库存 INT NOT NULL DEFAULT 0 COMMENT '该规格的独立库存',
    价格差 DECIMAL(10,2) DEFAULT 0 COMMENT '相对于商品基准价的差额（可正可负）',
    FOREIGN KEY (商品ID) REFERENCES 商品(商品ID) ON DELETE CASCADE
) COMMENT '商品的SKU信息，如颜色、尺寸等';

-- 9. 购物车表 (每个用户一个购物车)
CREATE TABLE 购物车 (
    购物车ID INT PRIMARY KEY COMMENT '购物车唯一标识',
    用户ID INT NOT NULL UNIQUE COMMENT '所属用户，一个用户只有一个购物车',
    创建时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '购物车创建时间',
    FOREIGN KEY (用户ID) REFERENCES 用户(用户ID)
) COMMENT '用户的购物车容器';

-- 10. 购物车项表 (购物车中的商品条目)
CREATE TABLE 购物车项 (
    购物车项ID INT PRIMARY KEY COMMENT '购物车项唯一标识',
    购物车ID INT NOT NULL COMMENT '所属购物车',
    商品ID INT NOT NULL COMMENT '加入的商品',
    规格ID INT DEFAULT NULL COMMENT '选择的商品规格（可为空）',
    数量 INT NOT NULL DEFAULT 1 COMMENT '商品数量',
    添加时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '加入购物车的时间',
    FOREIGN KEY (购物车ID) REFERENCES 购物车(购物车ID) ON DELETE CASCADE,
    FOREIGN KEY (商品ID) REFERENCES 商品(商品ID),
    FOREIGN KEY (规格ID) REFERENCES 商品规格(规格ID)
) COMMENT '购物车中的每个商品条目';

-- 11. 订单表
CREATE TABLE 订单 (
    订单ID INT PRIMARY KEY COMMENT '订单唯一标识',
    买家ID INT NOT NULL COMMENT '下单用户',
    下单时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '订单生成时间',
    总金额 DECIMAL(10,2) NOT NULL COMMENT '订单应付总金额',
    订单状态 VARCHAR(20) NOT NULL DEFAULT '待付款' COMMENT '状态：待付款/已付款/已发货/已完成/已取消',
    收货地址 TEXT NOT NULL COMMENT '收货详细地址',
    FOREIGN KEY (买家ID) REFERENCES 用户(用户ID)
) COMMENT '订单主表，记录订单头信息';

-- 12. 订单项表 (订单中的商品明细)
CREATE TABLE 订单项 (
    订单项ID INT PRIMARY KEY COMMENT '订单项唯一标识',
    订单ID INT NOT NULL COMMENT '所属订单',
    商品ID INT NOT NULL COMMENT '购买的商品',
    规格ID INT DEFAULT NULL COMMENT '购买时选择的规格',
    数量 INT NOT NULL COMMENT '购买数量',
    单价 DECIMAL(10,2) NOT NULL COMMENT '下单时的商品单价（快照）',
    FOREIGN KEY (订单ID) REFERENCES 订单(订单ID) ON DELETE CASCADE,
    FOREIGN KEY (商品ID) REFERENCES 商品(商品ID),
    FOREIGN KEY (规格ID) REFERENCES 商品规格(规格ID)
) COMMENT '订单中的每个商品条目，价格快照防止后续调价影响';

-- 13. 优惠券表 (平台或店铺发放)
CREATE TABLE 优惠券 (
    优惠券ID INT PRIMARY KEY COMMENT '优惠券唯一标识',
    店铺ID INT DEFAULT NULL COMMENT '所属店铺，NULL表示平台券',
    面额 DECIMAL(10,2) NOT NULL COMMENT '减免金额',
    使用门槛 DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '满多少元可用，0表示无门槛',
    有效期开始 DATE NOT NULL COMMENT '生效起始日',
    有效期结束 DATE NOT NULL COMMENT '失效日期',
    数量 INT NOT NULL COMMENT '发放总张数',
    FOREIGN KEY (店铺ID) REFERENCES 店铺(店铺ID)
) COMMENT '优惠券定义';

-- 14. 用户优惠券表 (用户领取记录，多对多中间表)
CREATE TABLE 用户优惠券 (
    用户ID INT NOT NULL COMMENT '领券用户',
    优惠券ID INT NOT NULL COMMENT '领取的优惠券',
    领取时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '领取时刻',
    是否使用 BOOLEAN DEFAULT FALSE COMMENT '是否已使用',
    PRIMARY KEY (用户ID, 优惠券ID),
    FOREIGN KEY (用户ID) REFERENCES 用户(用户ID),
    FOREIGN KEY (优惠券ID) REFERENCES 优惠券(优惠券ID)
) COMMENT '用户领取优惠券的记录';

-- 15. 支付记录表
CREATE TABLE 支付记录 (
    支付ID INT PRIMARY KEY COMMENT '支付流水号',
    订单ID INT NOT NULL UNIQUE COMMENT '关联订单，一个订单最终一次成功支付',
    支付方式 VARCHAR(20) NOT NULL COMMENT '支付方式：支付宝/微信/银行卡',
    支付金额 DECIMAL(10,2) NOT NULL COMMENT '实际支付金额',
    支付时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '支付完成时间',
    支付状态 VARCHAR(20) NOT NULL DEFAULT '成功' COMMENT '状态：成功/失败/退款',
    FOREIGN KEY (订单ID) REFERENCES 订单(订单ID)
) COMMENT '订单支付信息';

-- 16. 物流信息表
CREATE TABLE 物流信息 (
    物流ID INT PRIMARY KEY COMMENT '物流唯一标识',
    订单ID INT NOT NULL UNIQUE COMMENT '关联订单，一个订单对应一次发货',
    快递公司 VARCHAR(50) NOT NULL COMMENT '承运商，如顺丰',
    运单号 VARCHAR(50) NOT NULL COMMENT '快递单号',
    发货时间 DATETIME COMMENT '商家发货时间',
    签收时间 DATETIME DEFAULT NULL COMMENT '买家签收时间',
    物流轨迹 TEXT COMMENT 'JSON格式存储的物流状态历史',
    FOREIGN KEY (订单ID) REFERENCES 订单(订单ID)
) COMMENT '订单发货及物流跟踪';

-- 17. 评价表
CREATE TABLE 评价 (
    评价ID INT PRIMARY KEY COMMENT '评价唯一标识',
    订单项ID INT NOT NULL UNIQUE COMMENT '关联的订单项，一个订单项最多一条评价',
    用户ID INT NOT NULL COMMENT '发表评价的用户(买家)',
    评分 INT NOT NULL COMMENT '1-5星，整数',
    内容 TEXT NOT NULL COMMENT '评价文字内容',
    评价时间 DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '评价发表时间',
    商家回复 TEXT COMMENT '商家对评价的回复',
    FOREIGN KEY (订单项ID) REFERENCES 订单项(订单项ID),
    FOREIGN KEY (用户ID) REFERENCES 用户(用户ID)
) COMMENT '用户对购买商品的评价';

CREATE INDEX idx_商品_商家ID ON 商品(商家ID);
CREATE INDEX idx_商品_店铺ID ON 商品(店铺ID);
CREATE INDEX idx_商品_分类ID ON 商品(分类ID);
CREATE INDEX idx_订单_买家ID ON 订单(买家ID);
CREATE INDEX idx_订单_下单时间 ON 订单(下单时间);
CREATE INDEX idx_购物车项_购物车ID ON 购物车项(购物车ID);
