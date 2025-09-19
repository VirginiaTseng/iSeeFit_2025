"""
包含各种不同的JSON格式模板，用于文档分析
"""

# 采购合同JSON模板 - 根据md文件定义
PURCHASE_CONTRACT = '''
{
    "contractNo": "合同编号",
    "contractName": "合同名称",
    "buyer": "买方信息",
    "seller": "卖方信息",
    "paymentAccount": "付款账户",
    "receivingAccount": "收款账户",
    "signDate": "签订时间",
    "taxRate": "税率",
    "invoiceCategory": "发票类别",
    "invoiceType": "发票类型",
    "paymentDate": "付款日期",
    "paymentMethod": "付款方式",
    "minTolerance": "最小容差",
    "maxTolerance": "最大容差",
    "deliveryMethod": "履约方式（汽运/自提/水运等）",
    "startDate": "供货开始日期",
    "endDate": "供货结束日期",
    "location": "签约地点",
    "manager": "经办人",
    "totalPrice": "合同总价",
    "remarks": "备注",
    "goods": [
        {
            "name": "货物名称",
            "specification": "规格型号",
            "quantity": "数量",
            "unitPrice": "单价",
            "unit": "单位"
        }
        // ... 更多货物记录
    ]
}
'''

# 销售合同JSON模板 - 根据md文件定义
SALES_CONTRACT = '''
{
    "contractNo": "合同编号",
    "contractName": "合同名称",
    "buyer": "买方信息",
    "seller": "卖方信息",
    "paymentAccount": "付款账户",
    "receivingAccount": "收款账户",
    "signDate": "签订时间",
    "taxRate": "税率",
    "invoiceType": "发票类型",
    "paymentDate": "付款日期",
    "paymentMethod": "付款方式",
    "minTolerance": "最小容差",
    "maxTolerance": "最大容差",
    "deliveryMethod": "履约方式（汽运/自提/水运等）",
    "startDate": "供货开始日期",
    "endDate": "供货结束日期",
    "location": "签约地点",
    "manager": "经办人",
    "totalPrice": "合同总价",
    "remarks": "备注",
    "goods": [
        {
            "name": "货物名称",
            "specification": "规格型号",
            "quantity": "数量",
            "unitPrice": "单价",
            "unit": "单位"
        }
        // ... 更多货物记录
    ]
}
'''

# 运输合同JSON模板 - 根据md文件定义
TRANSPORT_CONTRACT = '''
{
    "contractNo": "合同编号",
    "contractName": "合同名称",
    "carrierInfo": "承运方信息",
    "shipperInfo": "托运方信息",
    "paymentAccount": "付款账户",
    "receivingAccount": "收款账户",
    "signDate": "签订时间",
    "taxRate": "税率",
    "invoiceType": "发票类型",
    "paymentDate": "付款日期",
    "paymentMethod": "付款方式",
    "totalPrice": "合同总价",
    "deliveryMethod": "运输方式",
    "startDate": "合同起始时间",
    "endDate": "合同截止时间",
    "manager": "经办人",
    "details": [
        {
            "origin": "起运地点",
            "destination": "收货单位",
            "goodsName": "货物名称",
            "unitPrice": "含税运输单价"
        }
        // ... 更多表格内运输明细
    ]
}
'''

# 入库质检单JSON模板 - 根据md文件定义
INBOUND_QUALITY_CHECK = '''
{
    "measurementNo": "计量号",
    "impurityDeduction": "扣杂",
    "netWeight": "结重",
    "date": "日期",
    "source": "来源",
    "radiationInspection": "放射性检测",
    "remarks": "备注",
    "items": [
        {
            "name": "品名",
            "percentage": "占比"
        }
        // ... 更多记录
    ],
    "disposals": [
        {
            "category": "处置物类别",
            "name": "处置物名称",
            "quantity": "数量（个）"
        }
        // ... 更多记录
    ]
}
'''

# 入库过磅单JSON模板 - 根据md文件定义
INBOUND_WEIGHING = '''
{
    "measurementNo": "计量号",
    "date": "日期",
    "grossWeight": "毛重",
    "tareWeight": "皮重",
    "netWeight": "净重",
    "radiationCheck": "放射性检测",
    "remarks": "备注"
}
'''

# 车牌号模板
INBOUND_VEHICLE = '''
{
    "vehicleNo": "车牌号",
    "driverName": "司机姓名",
    "driverPhone": "司机电话",
    "driverIdCard": "司机身份证号"
}
'''

# 出库质检单JSON模板 - 根据数据结构定义修改
OUTBOUND_QUALITY_CHECK = '''
{
    "measurementNo": "计量号",
    "impurityDeduction": "扣杂",
    "netWeight": "结重",
    "radiationInspection": "放射性检测",
    "remarks": "备注",
    "items": [
        {
            "itemName": "品名",
            "percentage": "占比"
        }
        // ... 更多记录
    ],
    "disposals": [
        {
            "category": "处置物类别",
            "name": "处置物名称",
            "quantity": "数量（个）"
        }
        // ... 更多记录
    ]
}
'''

# 出库过磅单JSON模板 - 根据md文件定义
OUTBOUND_WEIGHING = '''
{
    "measurementNo": "计量号",
    "grossWeight": "毛重",
    "tareWeight": "皮重",
    "netWeight": "净重",
    "radiationCheck": "放射性检测"
}
'''

# 采购运单JSON模板 - 根据提供的数据结构更新
PURCHASE_WAYBILL = '''
{
    "settlementNo": "结算单号",
    "settlementDate": "结算日期",
    "supplier": "供应商",
    "buyer": "购买方",
    "totalWeight": "总重量",
    "totalAmount": "总金额",
    "taxRate": "税率",
    "taxAmount": "税额",
    "paymentMethod": "付款方式",
    "invoiceCategory": "发票类别",
    "remarks": "备注",
    "measurements": [
        {
            "measurementNo": "计量号",
            "date": "日期",
            "vehicleNo": "车牌号",
            "grossWeight": "毛重",
            "tareWeight": "皮重",
            "netWeight": "净重",
            "finalWeight": "结重",
            "unitPrice": "单价",
            "amount": "金额"
        }
        // ... 更多计量记录
    ]
}
'''

# 销售运单JSON模板 - 根据md文件定义
SALES_WAYBILL = '''
{
    "waybillNo": "运单号",         
    "origin": "起运地",           
    "destination": "目的地",       
    "productName": "品名/种类",       
    "transportWeight": "运输重量(kg)",   
    "transportUnitPrice": "运输单价(元/kg)", 
    "transportAmount": "运输金额(元)",    
    "paidAmount": "已支付金额(元)",         
    "invoicedAmount": "已开票金额(元)",     
    "carrier": "承运者",          
    "transportMethod": "运输方式",  
    "waybillDate": "运单日期",      
    "department": "上传部门",       
    "status": "状态",    
    "remarks": "备注"           
}
'''

# 销售结算JSON模板 - 根据md文件定义
SALES_SETTLEMENT = '''
{
    "settlementNo": "结算单编号",
    "settlementDate": "结算日期",
    "supplier": "供货单位",
    "buyer": "购货单位",
    "totalAmount": "结算总金额",
    "totalWeight": "结算总重量",
    "taxRate": "税率",
    "taxAmount": "税额",
    "paymentMethod": "结算方式",
    "invoiceCategory": "发票类别",
    "remarks": "备注"
}
'''

# 采购付款记录JSON模板 - 根据md文件定义
PURCHASE_PAYMENT_RECORD = '''
{
    "transferRecordNo": "转账记录编号",
    "paymentMethod": "付款方式",
    "payerName": "付款人姓名",
    "payerContact": "付款人联系方式",
    "payeeName": "收款人姓名",
    "payeeContact": "收款人联系方式",
    "paymentAmount": "付款金额"
}
'''

# 销售收款记录JSON模板 - 根据md文件定义
SALES_RECEIPT_RECORD = '''
{
    "receiptNo": "收款单号",
    "receiptDate": "收款日期（x年x月x日x点x分x秒）",
    "receiptAmount": "收款金额",
    "receiptMethod": "收款方式",
    "payerName": "付款方户名",
    "payerAccount": "付款方账号",
    "payerBankName": "付款方银行名称（如中国农业银行，不包含具体支行）",
    "payerBankCode": "付款方银行代码",
    "payerBranchName": "付款方银行支行名称",
    "payeeName": "收款方户名",
    "payeeAccount": "收款方账号",
    "payeeBankName": "收款方银行名称（如中国农业银行，不包含具体支行）",
    "payeeBankCode": "收款方银行代码",
    "payeeBranchName": "收款方银行支行名称",
    "receiptPurpose": "收款用途",
    "remarks": "备注"
}
'''

# 采购收票JSON模板 - 根据md文件定义
PURCHASE_INVOICE_RECEIPT = '''
{
    "supplierName": "供应商名称",
    "supplierTaxNo": "供应商税号",
    "buyerName": "采购商名称",
    "buyerTaxNo": "采购商税号",
    "invoiceNo": "发票号码",
    "invoiceCode": "发票代码",
    "invoiceType": "发票类型",
    "amount": "发票金额",
    "taxRate": "税率",
    "taxAmount": "税额",
    "invoiceDate": "开票日期",
    "receiveDate": "收票日期",
    "remarks": "备注"
}
'''

# 采购反向开票JSON模板 - 根据md文件定义
PURCHASE_REVERSE_INVOICE = '''
{
    "sellerName": "销售方名称",
    "sellerTaxNo": "销售方纳税人识别号",
    "buyerName": "采购方名称",
    "buyerTaxNo": "采购方纳税人识别号",
    "amount": "金额（元）",
    "taxRate": "税率",
    "taxAmount": "税额"
}
'''

# 销售开票JSON模板 - 根据md文件定义
SALES_INVOICE = '''
{
    "sellerName": "销售方名称",
    "sellerTaxNo": "销售方纳税人识别号",
    "buyerName": "采购方名称",
    "buyerTaxNo": "采购方纳税人识别号",
    "amount": "金额（元）",
    "taxRate": "税率",
    "taxAmount": "税额"
}
'''

# 运输收票JSON模板 - 根据md文件定义
TRANSPORT_INVOICE_RECEIPT = '''
{
    "carrierName": "承运方名称",
    "carrierTaxNo": "承运方纳税人识别号",
    "consignorName": "托运方名称",
    "consignorTaxNo": "托运方纳税人识别号",
    "amount": "金额（元）",
    "taxRate": "税率",
    "taxAmount": "税额"
}
'''

# 司机信息JSON模板
DRIVER_INFO = '''
{
    "vehicleNo": "车牌号",
    "driverName": "司机姓名",
    "driverPhone": "司机电话",
    "driverIdCard": "司机身份证号"
}
'''

# 空模板 - 不使用预定义模板，让AI自行提取信息
EMPTY_TEMPLATE = '''
{}
'''

# 增加一个模板映射字典，方便根据名称获取对应的模板
TEMPLATES = {
    "purchase": PURCHASE_CONTRACT,
    "sales": SALES_CONTRACT,
    "transport": TRANSPORT_CONTRACT,
    "inbound_quality": INBOUND_QUALITY_CHECK,
    "inbound_weight": INBOUND_WEIGHING,
    "inbound_vehicle": INBOUND_VEHICLE,
    "outbound_quality_check": OUTBOUND_QUALITY_CHECK,
    "outbound_weight": OUTBOUND_WEIGHING,
    "purchase_waybill": PURCHASE_WAYBILL,
    "sales_waybill": SALES_WAYBILL,
    "sales_settlement": SALES_SETTLEMENT,
    "purchase_payment_record": PURCHASE_PAYMENT_RECORD,
    "sales_receipt_record": SALES_RECEIPT_RECORD,
    "purchase_invoice_receipt": PURCHASE_INVOICE_RECEIPT,
    "purchase_reverse_invoice": PURCHASE_REVERSE_INVOICE,
    "sales_invoice": SALES_INVOICE,
    "transport_invoice_receipt": TRANSPORT_INVOICE_RECEIPT,
    "driver_info": DRIVER_INFO,
    "none": EMPTY_TEMPLATE  # 添加空模板选项
}

# 默认模板
DEFAULT_TEMPLATE = EMPTY_TEMPLATE 