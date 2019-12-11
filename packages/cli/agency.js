var express             = require('express');
var app                 = express();
var bodyParse           = require('body-parser')
var cli = require('./cli')
var fs = require("fs")
app.use(bodyParse.urlencoded({extended:false})) ;

const path = require('path');
const utils = require('../api/common/utils');

const { Web3jService, ConsensusService, SystemConfigService } = require('../api');
const { ContractsDir, ContractsOutputDir } = require('../api/web3j/constant');

const web3 = new Web3jService();
const consensusService = new ConsensusService();
const systemConfigService = new SystemConfigService();

var contractAddr;

app.get('/agency', function(req,res){
	var contract = cli.main('deploy HelloWorld');
	contractAddr = contract.contractAddress;
	console.log(contract);
})

app.post('/register',function(req,res){
	var body = req.body;
	cli.main('call Agency ' + contractAddr + 'addCompany ' + body.address + ' ' + body.name + ' ' + body.cash + ' ' + body.cargo);
	console.log('注册');
	res.send(eval(body));
})

app.get('/register',function(req,res){
	fs.readFile("./resources/register.html", function(err, data){
		if(err){
			return console.log(err);
		}else{
			res.send(data.toString());
		}
	})
	console.log('register sendding')
})

app.post('/transaction',function(req,res){
        var body = req.body;
	var state = false;
	if(body.status){
		state = true;
	}
        cli.main('call Agency ' + contractAddr + 'addCompany ' + body.to + ' ' + body.from + ' ' + state + ' ' + body.payTime);
        console.log('交易');
        res.send(eval(body));
})

app.get('/transaction',function(req,res){
        fs.readFile("./resources/transaction.html", function(err, data){
                if(err){
                        return console.log(err);
                }else{
                        res.send(data.toString());
                }
        })
        console.log('transaction sendding')
})


app.get('/saleCredit', function(req,res){
	fs.readFile("./resources/sale.html", function(err, data){
                if(err){
                        return console.log(err);
                }else{
                        res.send(data.toString());
                }
        })
	console.log('sale sending')

})

app.post('/saleCredit',function(req,res){
        var body = req.body;
        cli.main('call Agency ' + contractAddr + 'sale ' + body.cash);
        console.log('出售债权');
        res.send(eval(body));
})



app.get('/saleCargo', function(req,res){
        fs.readFile("./resources/sale.html", function(err, data){
                if(err){
                        return console.log(err);
                }else{
                        res.send(data.toString());
                }
        })
        console.log('sale sending')

})

app.post('/saleCargo',function(req,res){
        var body = req.body;
        cli.main('call Agency ' + contractAddr + 'saleCargo ' + body.cash);
        console.log('出售货物');
        res.send(eval(body));
})


// 监听3000端口
console.info('listen 3000')
var server=app.listen(3000) ;

app.get('/stock', function(req,res){
        fs.readFile("./resources/stock.html", function(err, data){
                if(err){
                        return console.log(err);
                }else{
                        res.send(data.toString());
                }
        })
        console.log('stock sending')

})

app.post('/stock',function(req,res){
        var body = req.body;
        cli.main('call Agency ' + contractAddr + 'saleCargo ' + body.cash);
        console.log('购入货物');
        res.send(eval(body));
})
