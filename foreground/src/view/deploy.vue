<template>
  <div>
    <Card>
        <h1>合约部署信息</h1>
        <Row style = "margin: 10px 0">
            <Col span="20">
                <Row>
                    <Button type="primary" style="width: 100px; font-size: 13px; margin-right: 10px" @click="openAdd">部署合约</Button>
                </Row>
            </Col>
        </Row>
    </Card>
    <!-- //表格部分 -->
      <Card>
      <Table border :columns="columns" :data="datalist" disabled-hover></Table>
      <div style="margin: 10px;overflow: hidden">
          <div style="float: right;">
          <Page show-total show-elevator :total="page.total" :current="page.currentPage"
                  ></Page>
          </div>
      </div>
      </Card>
      <Modal v-model="isAdd" title="部署合约">
          <Form :model="addForm" ref="addForm" :label-width="110" :rules="addRules">
              <FormItem label="合约名称" prop="name" >
                  <Input  clearable v-model="addForm.name" placeholder = "请输入合约名称"/>
              </FormItem>
          </Form>
          <div slot="footer">
            <Button type="text" @click="cancelAdd">取消</Button>
          <Button type="primary" @click="doAdd">确认</Button>
      </div>
      </Modal>
      
  </div>
</template>