# 項目：Trend DAO
## Outline
- 一、項目介紹
- 二、項目特色
- 三、質押機制
- 四、鏈上治理
- 五、國庫運行
- 六、代幣經濟模型
- 七、智能合約互動及重點功能示意圖
- 八、團隊成員與負責事項
## 一、項目介紹
* Trend DAO 是一個去中心化的基金，投資者只要購買Trend Token或Trend Master NFT即可參與項目未來獲利分潤。購買Trend Token將可以分取Treasury收益，而購買Trend Master將可以分取Master Treasury的收益。而收益來源皆來自對Uniswap v2上項目幣的投資或資金池收益。

* 收益圖示：

![](https://hackmd.io/_uploads/Skhv37SVh.png)


<font color = 'blue'>ps: Treasury為中低風險型投資操作，Master Treasury為中高風險型投資操作。</font>
<font color = 'blue'>ps: Treasury和Master Treasury為多簽錢包，owner由理事會成員和項目團隊組成。</font>

## 二、項目特色
* 質押機制
* 鏈上治理
* 國庫運行

## 三、質押機制
* 持有Trend Token及Trend Master NFT的Holder可以質押賺取Trend Token作為利息。
* 持有Trend Token越多，便有機會從Treasury分到較多的分潤。
* 預計4年發放完畢所有質押利息。
* 質押示意圖：

![](https://hackmd.io/_uploads/Hy6rAiVE3.png)



## 四、鏈上治理
* Trend DAO的鏈上治理提案階段變化如下：

![](https://hackmd.io/_uploads/rJ2NRo4Nh.png)


* <b>CLOSED:</b> 表示提案被建立，但尚未開啟投票階段。
* <b>VOTING:</b> 表示有質押Trend Token的持有者可以對提案進行投票。
* <b>CONFIRMING:</b> 表示進行提案投票力結算。若提案通過門檻，則執行提案內容，並將提案狀態改為EXECUTED，反之，提案遭拒，REJECTED。
* <b>EXECUTED:</b> 表示提案通過並執行完畢。
* <b>REJECTED:</b> 表示提安遭拒。

<font color='blue'>ps: 階段的改變由項目方觸發，各階段的時間間距可由提案更動。</font>

* Trend DAO的鏈上治理有15個主題，分布在下方三個部分：
    * Proposal治理(4)
    * Council治理(9)
    * Treasury/Master Treasury治理(2)
 
### Proposal治理內容

* 針對提案的規則或限制進行治理，其中包括：
    * 調整提案者質押Trend Token門檻。
    * 調整提案需取得多少投票力才算提案通過。
    * 調整提案各階段時間間隔。
    * 調整取得投票力的質押Trend Token門檻。
### Council治理內容
* 針對理事會治理內容包括：
    * 發起理事會競選。
    * 發起理事會罷免。
    * 調整參與競選之候選人質押Trend Token門檻。
    * 調整理事會活動最低參與投票的門檻。
    * 調整理事會人數上限值。
    * 調整取得投票力的質押Trend Token門檻。
    * 調整當選理事會的所需獲得之得票力門檻。
    * 調整競選各階段時間間隔。
    * 調整罷免各階段時間間隔。

#### 理事會競選活動階段變化如下：

![](https://hackmd.io/_uploads/rkBzAsEV2.png)


* <b>CLOSED:</b> 表示理事會競選活動尚未開啟。
* <b>CANDIDATE_ATTENDING:</b> 表示現階段可讓符合質押Trend Token門檻的holder自願參選。
* <b>VOTING:</b> 表示有質押Trend Token的holder可以對候選人進行投票。
* <b>CONFIRMING:</b> 表示進行競選投票力結算，總參與投票力或者候選人最低得票門檻沒過，都可能造成競選無效。

<font color='blue'>ps: 階段的改變由項目方觸發，各階段的時間間距可由提案更動。</font>

#### 理事會罷免活動階段變化如下：

![](https://hackmd.io/_uploads/SJU70iNEn.png)

* <b>CLOSED:</b> 表示理事會罷免活動尚未開啟。
* <b>VOTING:</b> 表示有質押Trend Token的holder可以對罷免活動進行投票，有投票就表示同意罷免。
* <b>CONFIRMING:</b> 表示進行罷免投票力結算，總參與投票力門檻通過，則罷免成功。反之，罷免無效。

<font color='blue'>ps: 階段的改變由項目方觸發，各階段的時間間距可由提案更動。</font>
<font color='blue'>ps: 理事會競選及和罷免活動不會同時發生。</font>
<font color='blue'>ps: 成為理事會的地址會被新增進Treasury及Master Treasury的Owner。</font>

### Treasury治理內容
* 針對Treasury治理內容包括：
    * 調整Confirm次數（預設為半數+1）
* 針對Master Treasury治理內容包括：
    * 調整Confirm次數（預設為半數+1）

## 五、國庫運行
* 國庫有分兩種：
    * Treasury: 
        * 運作：
            * 利用捐贈或參與Trend Token公售的資金來賺取收益，並建立收益合約，按照持有的Trend Token比例進行分潤。
        * 定位：
            * 中地低風險
        * 投資手法：
            * 透過在Uniswap建立Trend Token/WETH流動池，並提供流動性賺取手續費。
            * 投資其他於Uniswap上有潛力的項目幣。
        * 示意圖：
        ![](https://hackmd.io/_uploads/HyrLGnEN3.png)
    * Master Treasury: 
        * 運作：
            * 利用參與Trend Master NFT白名單鑄造或荷蘭拍公售的資金來賺取收益，並建立收益合約，按照持有的Trend Master NFT比例進行分潤。
        * 定位：
            * 中高風險
        * 投資手法：
            * 投資其他於Uniswap上有潛力的項目幣。
        * 示意圖：
        ![](https://hackmd.io/_uploads/BJGKM2VNn.png)
    
## 六、Trend Token 代幣經濟模型
### 代幣分配
<table>
    <tr><th>標旳</th><th>幣量</th><th>備註</th></tr>
    <tr><th>總量</th><th>1,000,000,000</th><th></th></tr>
    <tr><td>Treasury</td><td>200,000,000</td><td>未來作為Uniswap提供流動性用</td></tr>
    <tr><td>顧問(Daniel)</td><td>30,000,000</td><td></td></tr>
    <tr><td>Token質押獎勵</td><td>450,000,000</td><td></td></tr>
    <tr><td>NFT質押獎勵</td><td>100,000,000</td><td>白名單 0.5ETH/顆、荷蘭拍1E~0.5E</td></tr>
    <tr><td>空投</td><td>20,000,000</td><td>用戶贊助1ETH即可獲得空投200,000顆，此價位相對為公售半價的價格，限量100名贊助者。</td></tr>
    <tr><td>公售</td><td>200,000,000</td><td>售價0.00001 ETH/ 顆</td></tr>
</table>

### 代幣用途
* <b>Trend Token：</b> 
    * 質押
    * 交易
    * 治理
    * Treasury分潤依據
* <b>Trend Master NFT:</b> 
    * 質押
    * Master Treasury分潤依據

## 七、智能合約互動及重點功能示意圖

![](https://hackmd.io/_uploads/r1szr3V43.png)

## 八、Roadmap

* 2023/03 項目規劃、訂定項目大方向
* 2023/04 項目智能合約開發
* 2023/05 項目前端開發
* 2023/05/07 智能合約上Sepolia測試網
* 2023/05/20 項目初步發表，公布第一版白皮書
* 2023 Q3 項目程式優化
* 2023 Q4 串接其他DEX及其他交易平台智能合約

## 九、Sepolia測試鏈部署：
* Trend Token: <a href="https://sepolia.etherscan.io/address/0xc60d31c92576c27b0a372220227dc25d52f00a99">0xC60d31c92576C27b0a372220227DC25d52f00a99</a>
* Trend Master NFT: <a href="https://sepolia.etherscan.io/address/0xee7af071a851ae66e193baf97914c999ef9b31a1">0xeE7Af071a851Ae66e193baF97914C999eF9b31a1</a>
* Token Staking Rewards:<a href="https://sepolia.etherscan.io/address/0xcf08f672d6dc1704004f79f3cf0a0d438aeda1a6">0xCF08f672D6dC1704004f79f3Cf0a0d438AEda1A6</a>
* NFT Staking Rewards:<a href="https://sepolia.etherscan.io/address/0x75475565a922c37703f2e2fd79bbe0bf32221703">0x75475565A922c37703f2E2FD79bBE0bf32221703</a>
* Token Airdrop:<a href="https://sepolia.etherscan.io/address/0xecdc525763ef0d01e67d3c9b24182fd6cd973dfb">0xeCDC525763Ef0D01e67d3c9b24182fd6cD973dFB</a>
* Proposal:<a href="https://sepolia.etherscan.io/address/0xc62e0e66cd1b320d3cf21cdcc4345cc9a4bbaa0d">0xC62e0e66cD1b320d3CF21CDcc4345CC9a4BBaA0d</a>
* Council: <a href="https://sepolia.etherscan.io/address/0x7cc7550ed84f05eecdae103cf930c6a6a1f82a98">0x7Cc7550ED84f05EEcdaE103CF930c6A6a1f82A98</a>
* Treasury:<a href="0x34fc204809bc337c04BAE71528629cD28F702Be7">0x34fc204809bc337c04BAE71528629cD28F702Be7</a>
* Master Treasury:<a href="https://sepolia.etherscan.io/address/0xa804f7f5cf16088b929c641a20597363489846ed">0xa804F7f5CF16088B929C641a20597363489846Ed</a>
* Uniswap Invest: <a href="https://sepolia.etherscan.io/address/0x6b85bc63318f177117154ae6b999b4bffbbb59ed">0x6B85Bc63318F177117154Ae6B999B4BffBbb59Ed</a>

## 十、團隊成員與負責事項
### 成員介紹與定位

<img src="https://i.imgur.com/8PK57fa.png" width=25% height=25%>&nbsp; <span><b>Daniel</b></span> &nbsp;&nbsp;<span>提供技術諮詢、自帶Georli水龍頭功能<3。</span>

<img src="https://hackmd.io/_uploads/Sk1Pb34Nh.jpg" width=25% height=25%>&nbsp; <span><b>Paul</b></span> &nbsp;&nbsp;<span>智能合約開發、前端治理功能、項目規劃</span>

<img src="https://i.imgur.com/eUF4nmh.png" width=25% height=25%>&nbsp; <span><b>Andrew</b></span> &nbsp;&nbsp;<span>智能合約輔助開發、前端空投功能、NFT製圖</span>

<img src="https://i.imgur.com/Yslc9A9.png" width=25% height=25%>&nbsp; <span><b>Steve</b></span> &nbsp;&nbsp;<span>前端Token/NFT、質押功能</span>


## Github
* 智能合約：https://github.com/paulwu0903/Kryptocamp_final_project
* 前端網頁：https://github.com/stevecyj/krypto-final
* Demo網頁：https://krypto-final.vercel.app/#/index

