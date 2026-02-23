import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'lib/core/blockchain/evm/erc20/erc20_service.dart';

void main() async {
  final client = Web3Client('https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28', Client());
  final ethService = Erc20Service(client);
  
  try {
    final bal = await ethService.balanceOf(
      contractAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
      walletAddress: '0xE43726738e770F667c5536aBcb64c7AEeaBd823F'
    );
    print('USDC Balance: $bal');
  } catch (e) {
    print('Error: $e');
  }
}
