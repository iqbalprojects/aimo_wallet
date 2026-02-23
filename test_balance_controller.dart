import 'package:get/get.dart';
import 'lib/features/wallet/domain/usecases/get_balance_usecase.dart';
import 'lib/core/network/rpc_client.dart';

void main() async {
  final rpc = RpcClientImpl(rpcUrl: 'https://mainnet.infura.io/v3/363def80155a4bda9db9a2203db6ca28');
  final uc = GetBalanceUseCase(rpcClient: rpc);
  try {
    final bal = await uc.call(address: '0xE43726738e770F667c5536aBcb64c7AEeaBd823F');
    print('Balance Eth: ${bal.balanceEth}');
  } catch(e, st) {
    print('Error: $e\n$st');
  }
}
