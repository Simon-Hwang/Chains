pragma solidity ^0.4.21;

contract Agency{
	address public agencyAddr;
	
	struct Company{ //在第三方处注册的公司才能进行有效的债权转让
		address companyAddr;
		bytes32 companyName;
		bool canTrust; // 由Agency判断公司是否可信
		bool isUsed;
		uint receiveableLength;  //由于账款长度变化 以此记录长度 而非直接用.length
		uint cashAccount; //现金
		uint cargoAccount; // 货物资产 
	}
	struct Credit{	//记录账款
		address to;
		address from1;
		uint amount;
		uint buildDate; //账款创建日期
		uint payDate;//日期限制 测试以秒为单位 便于快速观察
	}
	
	mapping(address => Credit[]) public accountsReceivable;// 应收账款
	mapping(address => Company) public companys;
	bool status; //查看合约调用时的状态  false表示处理失败
	Credit credit; //临时变量
	uint[] index;//A 可能存到从B多个不同期限的贷款 而进行债券转化时可以大于其中一个贷款 因此可能有多个债权需要更改
	
	constructor(){
		agencyAddr = msg.sender;
		companys[agencyAddr] = Company({
			companyAddr: agencyAddr,
			companyName: bytes32("Agency"),
			canTrust: true,
			isUsed: true,
			receiveableLength: 0,
			cashAccount: 100000, //足够大
			cargoAccount:100000
		});
	}
	
	function addCompany(address addr, bytes32 name, uint cash, uint cargo) public{
		require(msg.sender == agencyAddr); //Only the agency can register a new company
		bool trust = false;
		if(cash + cargo >= 1000){
			trust = true; //当公司注册资产大于1000时，认为该公司可信
		}
		companys[addr] = Company({
			companyAddr: addr,
			companyName: name,
			canTrust: trust,
			isUsed: true,
			receiveableLength: 0,
			cashAccount: cash,
			cargoAccount:cargo
		});
	}
	
	function transfer(address toOld, address toNew, address fromAddr, uint account) public{ //债权转移 并处理转移后的变量
		status = false;
		//require(msg.sender == toOld); //不能校验这个 因为repayment函数调用到transfer此时msg.sender为toNew
		require(companys[toOld].isUsed && companys[toNew].isUsed && companys[fromAddr].isUsed);
		require(toNew != fromAddr);//"obligor can not be the same as creditor"
		
		//处理 to
		delete(index);
		uint curAccount = 0;
		for(uint i = 0; i < companys[toOld].receiveableLength; i++){
			if(accountsReceivable[toOld][i].from1 == fromAddr){
				curAccount += accountsReceivable[toOld][i].amount;
				index.push(i);// 记录下转让方需要处理的特定债权下标
				if(curAccount >= account){
					break;
				}
			}
		}
		require(curAccount >= account); //债权总额不足 "There are no enough account to transfer"
		require(index.length > 0);
		uint tmpLength = companys[toOld].receiveableLength;
		if(curAccount > account){//部分债权转移需要考虑怎么转 避免覆盖
			Credit creTmp = accountsReceivable[toOld][index[0]];
			accountsReceivable[toOld][index[0]] = accountsReceivable[toOld][index[index.length - 1]];
			accountsReceivable[toOld][index[index.length - 1]] = creTmp; //调转
			for(i = index.length - 1; i >= 1; i--){ //后length - 1个是整个债券转让  第1个是部分债权转让
				credit = accountsReceivable[toOld][index[i]];
				addCredit(toNew);
				accountsReceivable[toOld][index[i]] = accountsReceivable[toOld][tmpLength + i - index.length];
				if(i == 0 || i >= index.length){
					break;
				}
			}
			companys[toOld].receiveableLength = companys[toOld].receiveableLength - index.length + 1;
			credit = accountsReceivable[toOld][index[0]];
			credit.amount = credit.amount - (curAccount - account); // 总的-剩余的=转移的
			accountsReceivable[toOld][index[0]].amount = curAccount - account; //剩余的债权curAccount - account
			addCredit(toNew);
		}else{
			for(i = index.length - 1; i >= 0; i--){ //从后往前避免出错
				credit = accountsReceivable[toOld][index[i]];
				addCredit(toNew);
				accountsReceivable[toOld][index[i]] = accountsReceivable[toOld][tmpLength + i - index.length];
				if(i == 0 || i >= index.length){
					break;
				}
			}
			companys[toOld].receiveableLength -= index.length;
		}
		status = true;
	}
	
	function addCredit(address addr) internal{ //增加债权 反正都是债主 没必要检查地址
		credit.to = addr; //处理方便一些
		if(companys[addr].receiveableLength < accountsReceivable[addr].length){ 
			accountsReceivable[addr][companys[addr].receiveableLength] = credit;
		}else{
			accountsReceivable[addr].push(credit);
		}
		companys[addr].receiveableLength += 1;
	}
	
	function saleCargo(uint account) public { //用于上流汽车公司或其他公司直接卖出货物 此时默认现金交易
		address company = msg.sender;
		require(companys[company].cargoAccount >= (account / 2) );
		companys[company].cargoAccount -= account / 2; //没有利润公司经营不下去 整条链不能有效持续
		companys[company].cashAccount += account;
	}
	
	function saleCredit(uint account) public{ // 卖出债权到金融机构
		status = false;
		address checkAddr = msg.sender;
		delete(index);
		uint surplus;
		for(uint j = 0; j < companys[checkAddr].receiveableLength; j++){ //credit.from1是还款人  
			surplus += accountsReceivable[checkAddr][j].amount; //记录还款人需要进行其名下的债权转让的债款下标
			index.push(j);
			if(surplus >= account){
				break;
			}
		}
		require(surplus >= account);
		if(surplus == account){
			for(uint i = 0; i < index.length; i++){
				transfer(checkAddr, agencyAddr, accountsReceivable[checkAddr][j].from1, accountsReceivable[checkAddr][j].amount);
			}
		}else{
			for(i = 0; i < index.length - 1; i++){
				transfer(checkAddr, agencyAddr, accountsReceivable[checkAddr][j].from1, accountsReceivable[checkAddr][j].amount);
			}
			transfer(checkAddr, agencyAddr, accountsReceivable[checkAddr][index.length - 1].from1, accountsReceivable[checkAddr][index.length - 1].amount - (surplus - account));
		}
		companys[checkAddr].cargoAccount += account;
		status = true;
	}
	
	function stock(uint account) public{ //同理， 用于直接进货
		status = false;
		address company = msg.sender;
		require(companys[company].cashAccount >= account );
		companys[company].cargoAccount += account ;
		companys[company].cashAccount -= account;
		status = true;
	}	
	
	function transaction(address to, address fromAddr, uint account, bool status1, uint payTime) public{ //从from1向to发起交易 status为true直接用现金支付 为false发起贷款
		status = false;
		require(msg.sender == fromAddr);
		require(companys[to].isUsed && companys[fromAddr].isUsed);
		require(to != agencyAddr); //金融机构不购买货物 只购买债权
		if(status1 == true){
			require(companys[fromAddr].cashAccount >= account && companys[to].cargoAccount > (account / 2));
			companys[fromAddr].cargoAccount += account; // 对于from1而言 货物的价格就是买来的价格 因此+account而不/2 
			companys[fromAddr].cashAccount -= account;
			companys[to].cargoAccount -= account / 2; //认为利润为2倍的货物价格 因此买500w的货物实际上只减少了250w的货物存量
			companys[to].cashAccount += account;
		}else{ 
			require(companys[fromAddr].canTrust);//此时需要from1地址公司的canTrust为true 才能贷款
			require(companys[to].cargoAccount >= (account / 2));
			credit = Credit({
				to: to,
				from1: fromAddr,
				amount: account,
				buildDate: now,
				payDate: payTime
			});
			addCredit(to);
			companys[fromAddr].cargoAccount += account;
			companys[to].cargoAccount -= account / 2; //认为利润为2倍的货物价格 因此买500w的货物实际上只减少了250w的货物存量
		}
		status = true; //交易建立成功
	}
	
	function repayment(address checkAddr) public{ //检查checkAddr(便于Agency去调用)对应公司的应收账款是否到期 到期则负责收回
		status = false;
		for(uint i = companys[checkAddr].receiveableLength - 1; i >= 0 ; i--){ //新添加的债权都在后 因此不影响
			credit = accountsReceivable[checkAddr][i];
			if(now >= credit.buildDate + credit.payDate * 1){ //到了还款日期
				if(companys[credit.from1].cashAccount >= credit.amount){
					companys[credit.from1].cashAccount -= credit.amount; //用现金还款
					companys[credit.to].cashAccount += credit.amount;
				}else{//现金+债权还款
					//先判断是否有足够的债权进行转移
					uint surplus = companys[credit.from1].cashAccount;
					delete(index);
					for(uint j = 0; j < companys[credit.from1].receiveableLength; j++){ //credit.from1是还款人  
						surplus += accountsReceivable[credit.from1][j].amount; //记录还款人需要进行其名下的债权转让的债款下标
						index.push(j);
						if(surplus >= credit.amount){
							break;
						}
					}
					require(surplus >= credit.amount); //还款失败
					companys[credit.from1].cashAccount = 0;
					if(surplus > credit.amount){
						for(j = 0; j < index.length - 1; j++){ //不区分fromAddr来转让债权
							transfer(credit.from1, checkAddr, accountsReceivable[credit.from1][j].from1, accountsReceivable[credit.from1][j].amount); //全部转让
						}
						transfer(credit.from1, checkAddr, accountsReceivable[credit.from1][index.length - 1].from1, accountsReceivable[credit.from1][index.length - 1].amount - (surplus - credit.amount));//转让部分
					}else{
						for(j = 0; j < index.length; j++){ //不区分fromAddr来转让债权
							transfer(credit.from1, checkAddr, accountsReceivable[credit.from1][j].from1, accountsReceivable[credit.from1][j].amount); //全部转让
						}
					}
				}
				accountsReceivable[checkAddr][i] = accountsReceivable[checkAddr][companys[checkAddr].receiveableLength - 1];//transfer
				companys[checkAddr].receiveableLength -= 1; //去除账单 
			}
			if(i == 0){
				break;
			}
		}
		status = true;
	}
}

	