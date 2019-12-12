import { fetch, post, patch, del } from './http'
// ---------------------终端分组管理-------------------------
// 添加
export function select (params) {
  return post('/api/select', params)
}

// // 编辑
// export function edit (params) {
//   return patch('/api/0.1/informationReleaseLogManage/update', params)
// }

// // 删除
// export function delet (params) {
//   return del('/api/0.1/informationReleaseLogManage/del', params)
// }

// // 批量删除
// export function delMany (params) {
//   return del('/api/0.1/informationReleaseLogManage/deleteMany', params)
// }

// // 获得列表
// export function findList (params) {
//   return fetch('/api/0.1/informationReleaseLogManage/list', params)
// }
