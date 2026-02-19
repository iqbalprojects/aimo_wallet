import 'package:web3dart/web3dart.dart';
import 'erc20_abi.dart';

/// Exception thrown by ERC20 service operations.
class Erc20Exception implements Exception {
  final String message;
  final String? details;

  Erc20Exception(this.message, {this.details});

  @override
  String toString() => 'Erc20Exception: $message';
}

/// Service for interacting with ERC20 token contracts.
///
/// Provides read-only operations and transaction building for ERC20 tokens.
/// This service does NOT sign or broadcast transactions - it only reads
/// data and prepares transactions for signing.
///
/// Security:
/// - No private key handling
/// - No transaction signing
/// - No transaction broadcasting
/// - Contract addresses are validated before use
///
/// Usage:
/// ```dart
/// final service = Erc20Service(client);
///
/// // Read token balance
/// final balance = await service.balanceOf(
///   contractAddress: '0x...',
///   walletAddress: '0x...',
/// );
///
/// // Build approve transaction (unsigned)
/// final tx = await service.buildApproveTransaction(
///   contractAddress: '0x...',
///   spender: '0x...',
///   amount: BigInt.from(1000000000000000000),
/// );
/// // Sign and broadcast elsewhere
/// ```
///
/// This service is reusable for:
/// - Token dashboard (balances, metadata)
/// - Swap operations (allowance, approve)
/// - Token management screens
class Erc20Service {
  final Web3Client _client;

  /// Creates an ERC20 service with the given Web3Client.
  ///
  /// The client should be connected to an RPC endpoint.
  /// The caller is responsible for managing the client lifecycle.
  Erc20Service(this._client);

  /// Queries the token balance of an address.
  ///
  /// Calls the `balanceOf(address)` function on the ERC20 contract.
  ///
  /// Parameters:
  /// - contractAddress: ERC20 token contract address
  /// - walletAddress: Address to query balance for
  ///
  /// Returns: Token balance as BigInt (in smallest units)
  ///
  /// Throws: Erc20Exception if address is invalid or call fails
  Future<BigInt> balanceOf({
    required String contractAddress,
    required String walletAddress,
  }) async {
    try {
      final contract = _getContract(contractAddress);
      final wallet = _parseAddress(walletAddress);

      final result = await _client.call(
        contract: contract,
        function: contract.function('balanceOf'),
        params: [wallet],
      );

      return (result[0] as BigInt);
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Erc20Exception(
        'Failed to get token balance',
        details: e.toString(),
      );
    }
  }

  /// Queries the allowance granted to a spender by an owner.
  ///
  /// Calls the `allowance(address,address)` function on the ERC20 contract.
  /// Returns the amount of tokens the spender is authorized to transfer
  /// on behalf of the owner.
  ///
  /// Parameters:
  /// - contractAddress: ERC20 token contract address
  /// - owner: Address that owns the tokens
  /// - spender: Address that is authorized to spend
  ///
  /// Returns: Allowance amount as BigInt (in smallest units)
  ///
  /// Throws: Erc20Exception if addresses are invalid or call fails
  Future<BigInt> allowance({
    required String contractAddress,
    required String owner,
    required String spender,
  }) async {
    try {
      final contract = _getContract(contractAddress);
      final ownerAddress = _parseAddress(owner);
      final spenderAddress = _parseAddress(spender);

      final result = await _client.call(
        contract: contract,
        function: contract.function('allowance'),
        params: [ownerAddress, spenderAddress],
      );

      return (result[0] as BigInt);
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Erc20Exception('Failed to get allowance', details: e.toString());
    }
  }

  /// Builds an unsigned approve transaction.
  ///
  /// Creates a transaction object that calls `approve(address,uint256)`
  /// on the ERC20 contract. This transaction must be signed and
  /// broadcast separately.
  ///
  /// IMPORTANT: This does NOT sign or broadcast the transaction.
  /// The caller must:
  /// 1. Sign with user's private key
  /// 2. Broadcast to the network
  /// 3. Wait for confirmation
  ///
  /// Parameters:
  /// - contractAddress: ERC20 token contract address
  /// - spender: Address to approve for spending
  /// - amount: Amount to approve (in smallest units)
  ///
  /// Returns: Unsigned Transaction object ready for signing
  ///
  /// Throws: Erc20Exception if addresses are invalid or build fails
  Future<Transaction> buildApproveTransaction({
    required String contractAddress,
    required String spender,
    required BigInt amount,
  }) async {
    try {
      final contract = _getContract(contractAddress);
      final spenderAddress = _parseAddress(spender);

      // Build unsigned transaction for approve call
      return Transaction.callContract(
        contract: contract,
        function: contract.function('approve'),
        parameters: [spenderAddress, amount],
      );
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Erc20Exception(
        'Failed to build approve transaction',
        details: e.toString(),
      );
    }
  }

  /// Queries the decimals of an ERC20 token.
  ///
  /// Calls the `decimals()` function on the ERC20 contract.
  /// Standard tokens use 18 decimals, but some use different values.
  ///
  /// Parameters:
  /// - contractAddress: ERC20 token contract address
  ///
  /// Returns: Number of decimals (typically 18)
  ///
  /// Throws: Erc20Exception if address is invalid or call fails
  Future<int> decimals(String contractAddress) async {
    try {
      final contract = _getContract(contractAddress);

      final result = await _client.call(
        contract: contract,
        function: contract.function('decimals'),
        params: [],
      );

      // decimals() returns uint8, which is a BigInt in web3dart
      return (result[0] as BigInt).toInt();
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Erc20Exception(
        'Failed to get token decimals',
        details: e.toString(),
      );
    }
  }

  /// Queries the symbol of an ERC20 token.
  ///
  /// Calls the `symbol()` function on the ERC20 contract.
  /// Returns the token's ticker symbol (e.g., "USDT", "DAI").
  ///
  /// Parameters:
  /// - contractAddress: ERC20 token contract address
  ///
  /// Returns: Token symbol as string
  ///
  /// Throws: Erc20Exception if address is invalid or call fails
  Future<String> symbol(String contractAddress) async {
    try {
      final contract = _getContract(contractAddress);

      final result = await _client.call(
        contract: contract,
        function: contract.function('symbol'),
        params: [],
      );

      return (result[0] as String);
    } on Erc20Exception {
      rethrow;
    } catch (e) {
      throw Erc20Exception('Failed to get token symbol', details: e.toString());
    }
  }

  /// Creates a DeployedContract instance from address and ABI.
  ///
  /// Uses the erc20Abi constant for the contract interface.
  ///
  /// Parameters:
  /// - address: ERC20 contract address
  ///
  /// Returns: DeployedContract ready for calls
  ///
  /// Throws: Erc20Exception if address is invalid
  DeployedContract _getContract(String address) {
    final ethereumAddress = _parseAddress(address);

    return DeployedContract(
      ContractAbi.fromJson(erc20Abi, 'ERC20'),
      ethereumAddress,
    );
  }

  /// Parses and validates an Ethereum address.
  ///
  /// Validates:
  /// - Starts with 0x
  /// - Is 42 characters (0x + 40 hex)
  /// - Contains only valid hex characters
  ///
  /// Parameters:
  /// - address: Address string to parse
  ///
  /// Returns: EthereumAddress object
  ///
  /// Throws: Erc20Exception if address is invalid
  EthereumAddress _parseAddress(String address) {
    // Check format
    if (!address.startsWith('0x')) {
      throw Erc20Exception('Invalid address format: must start with 0x');
    }

    if (address.length != 42) {
      throw Erc20Exception(
        'Invalid address length: must be 42 characters (0x + 40 hex)',
      );
    }

    // Check hex characters
    final hexPart = address.substring(2);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hexPart)) {
      throw Erc20Exception(
        'Invalid address format: contains non-hex characters',
      );
    }

    // Parse with web3dart
    try {
      return EthereumAddress.fromHex(address);
    } catch (e) {
      throw Erc20Exception('Invalid Ethereum address', details: e.toString());
    }
  }
}
