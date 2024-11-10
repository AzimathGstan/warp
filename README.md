# wARP

An APP that scan the local network.
Though Despite it's name. One can't really send ARP in unrooted android device.
So it's just a simple network scanner based on ping.

NOTICE: This is a "homework" project. Therefore I suggest you only use it
for learning (if you can find anything useful here).

用來掃描本地網路的APP。
儘管名子裡有ARP，雖然本身的計畫中有ARP的部份（可能會在Linux裡實現）。
但我們的目標還是以Android為主。
目前Android在非Root的情況下，就我目前認知，只有ping可以正常使用。
ARP並不能夠穩定的發出，且基本上無Root完全不能接收。
ICMP也是，但是ping指令是少數能夠在執行著無Root的情況下可以收發ICMP封包。

## Features 功能

Very simple. You open the app. Choose one network interface.
On the right upper corner. And swipe up. Then its done.

非常簡單。打開APP。選擇一個網路介面。
在右上角選擇網路界面。然後向下滑動。就完成了。

## How it works 原理
IP Address scanning: We use ping command(executable) in the rom.

IP地址掃描：我們使用ROM裡的ping命令（執行檔）。

OS guessing: We use TTL from ping response to guess the OS.

作業系統猜測：我們使用ping回應的TTL來猜測作業系統。

## Project Status Project狀態

Currently only Android's backend really works.
The Linux backend despite works before. 
But after the redo of the frontend and backend communication.
It's not working anymore. There are no plans to fix it for now.

目前只有Android的後端可以正常工作。
Linux的後端在前後端通訊重製前可以工作，
但在重製後Linux的後端還沒有完成。
目前也沒有計畫要去處理。

| Platform | Ping | MAC | OS |
| ---      | ---  | --- | -- |
| Android  | ✓    | ✘   | ✓(TTL) |
| Linux    | ✘    | ✘   | ✘  |




