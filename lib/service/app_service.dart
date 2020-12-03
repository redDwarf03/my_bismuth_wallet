import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:event_taxi/event_taxi.dart';
import 'package:logger/logger.dart';
import 'package:my_bismuth_wallet/bus/events.dart';
import 'package:my_bismuth_wallet/bus/subscribe_event.dart';
import 'package:my_bismuth_wallet/network/model/response/addlistlim_response.dart';
import 'package:my_bismuth_wallet/network/model/response/address_txs_response.dart';
import 'package:my_bismuth_wallet/network/model/response/balance_get_response.dart';
import 'package:my_bismuth_wallet/network/model/response/servers_wallet_legacy.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response.dart';

import 'package:my_bismuth_wallet/network/model/response/simple_price_response_aed.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_ars.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_aud.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_brl.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_btc.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_cad.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_chf.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_clp.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_cny.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_czk.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_dkk.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_eur.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_gbp.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_hkd.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_huf.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_idr.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_ils.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_inr.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_jpy.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_krw.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_kwd.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_mxn.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_myr.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_nok.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_nzd.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_php.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_pkr.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_pln.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_rub.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_sar.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_sek.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_sgd.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_thb.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_try.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_twd.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_usd.dart';
import 'package:my_bismuth_wallet/network/model/response/simple_price_response_zar.dart';

class AppService {
  var logger = Logger();

  String getLengthBuffer(String message) {
    return message == null ? null : message.length.toString().padLeft(10, '0');
  }

  Future<ServerWalletLegacyResponse> getBestServerWalletLegacyResponse() async {
    List<ServerWalletLegacyResponse> serverWalletLegacyResponseList =
        new List<ServerWalletLegacyResponse>();
    ServerWalletLegacyResponse serverWalletLegacyResponse =
        new ServerWalletLegacyResponse();

    HttpClient httpClient = new HttpClient();
    try {
      HttpClientRequest request = await httpClient.getUrl(
          Uri.parse("http://api.bismuth.live/servers/wallet/legacy.json"));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        print("serverWalletLegacyResponseList=" + reply);
        serverWalletLegacyResponseList =
            serverWalletLegacyResponseFromJson(reply);

        // Best server active with less clients
        serverWalletLegacyResponseList
            .removeWhere((element) => element.active == false);
        serverWalletLegacyResponseList.sort((a, b) {
          return a.clients
              .toString()
              .toLowerCase()
              .compareTo(b.clients.toString().toLowerCase());
        });
        if (serverWalletLegacyResponseList.length > 0) {
          serverWalletLegacyResponse = serverWalletLegacyResponseList[0];
        }
      }
    } catch (e) {} finally {
      httpClient.close();
    }
    print("Server Wallet : " +
        serverWalletLegacyResponse.ip +
        ":" +
        serverWalletLegacyResponse.port.toString());
    return serverWalletLegacyResponse;
  }

  Future<BalanceGetResponse> getBalanceGetResponse(String address) async {
    BalanceGetResponse balanceGetResponse = new BalanceGetResponse();
    try {
      ServerWalletLegacyResponse serverWalletLegacyResponse =
          await getBestServerWalletLegacyResponse();
      print("serverWalletLegacyResponse.ip : " + serverWalletLegacyResponse.ip);
      print("serverWalletLegacyResponse.port : " +
          serverWalletLegacyResponse.port.toString());
      Socket.connect(
              serverWalletLegacyResponse.ip, serverWalletLegacyResponse.port)
          .then((Socket socket) {
        print('Connected to: '
            '${socket.remoteAddress.address}:${socket.remotePort}');
        //Establish the onData, and onDone callbacks
        socket.listen((data) {
          if (data != null) {
            String message = new String.fromCharCodes(data).trim();
            message = message.substring(
                10, 10 + int.tryParse(message.substring(0, 10)));
            balanceGetResponse = balanceGetResponseFromJson(message);
            balanceGetResponse.address = address;
            print(message);
            EventTaxiImpl.singleton()
                .fire(SubscribeEvent(response: balanceGetResponse));
            socket.close();
            return balanceGetResponse;
          }
        }, onDone: () {
          print("Done");
          socket.destroy();
        });

        //Send the request
        String method = '"balancegetjson"';
        String param = '"' + address + '"';

        socket.write(
            getLengthBuffer(method) + method + getLengthBuffer(param) + param);
      });
    } catch (e) {
      print("pb socket" + e.toString());
    } finally {}
  }

  Future<AddressTxsResponse> getAddressTxsResponse(
      String address, int limit) async {
    AddressTxsResponse addressTxsResponse = new AddressTxsResponse();

    addressTxsResponse.result = new List<AddressTxsResponseResult>();
    Completer<AddressTxsResponse> _completer =
        new Completer<AddressTxsResponse>();
    try {
      ServerWalletLegacyResponse serverWalletLegacyResponse =
          await getBestServerWalletLegacyResponse();
      print("serverWalletLegacyResponse.ip : " + serverWalletLegacyResponse.ip);
      print("serverWalletLegacyResponse.port : " +
          serverWalletLegacyResponse.port.toString());

      Socket _socket = await Socket.connect(
          serverWalletLegacyResponse.ip, serverWalletLegacyResponse.port);

      print('Connected to: '
          '${_socket.remoteAddress.address}:${_socket.remotePort}');
      //Establish the onData, and onDone callbacks
      _socket.listen((data) {
        if (data != null) {
          String message = new String.fromCharCodes(data).trim();

          message = message.substring(
              10, 10 + int.tryParse(message.substring(0, 10)));
          print(message);
          List txs = addlistlimResponseFromJson(message);
          for (int i = 0; i < txs.length; i++) {
            AddressTxsResponseResult addressTxResponse =
                new AddressTxsResponseResult();
            addressTxResponse.populate(txs[i], address);
            addressTxsResponse.result.add(addressTxResponse);
          }
          _completer.complete(addressTxsResponse);
        }
      }, onError: ((error, StackTrace trace) {
        print("Error");
        _completer.complete(addressTxsResponse);
      }), onDone: () {
        print("Done");
        _socket.destroy();
      }, cancelOnError: false);

      //Send the request
      String method = '"addlistlim"';
      String param1 = '"' + address + '"';
      String param2 = '"' + limit.toString() + '"';
      _socket.write(getLengthBuffer(method) +
          method +
          getLengthBuffer(param1) +
          param1 +
          getLengthBuffer(param2) +
          param2);
    } catch (e) {
      print("pb socket" + e.toString());
    } finally {}
    return _completer.future;
  }

  Future<SimplePriceResponse> getSimplePrice(String currency) async {
    SimplePriceResponse simplePriceResponse = new SimplePriceResponse();
    simplePriceResponse.currency = currency;

    HttpClient httpClient = new HttpClient();
    try {
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(
          "https://api.coingecko.com/api/v3/simple/price?ids=bismuth&vs_currencies=BTC"));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        SimplePriceBtcResponse simplePriceBtcResponse =
            simplePriceBtcResponseFromJson(reply);
        simplePriceResponse.btcPrice = simplePriceBtcResponse.bismuth.btc;
      }

      request = await httpClient.getUrl(Uri.parse(
          "https://api.coingecko.com/api/v3/simple/price?ids=bismuth&vs_currencies=" +
              currency));
      request.headers.set('content-type', 'application/json');
      response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        switch (currency.toUpperCase()) {
          case "ARS":
            SimplePriceArsResponse simplePriceLocalResponse =
                simplePriceArsResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.ars;
            break;
          case "AUD":
            SimplePriceAudResponse simplePriceLocalResponse =
                simplePriceAudResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.aud;
            break;
          case "BRL":
            SimplePriceBrlResponse simplePriceLocalResponse =
                simplePriceBrlResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.brl;
            break;
          case "CAD":
            SimplePriceCadResponse simplePriceLocalResponse =
                simplePriceCadResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.cad;
            break;
          case "CHF":
            SimplePriceChfResponse simplePriceLocalResponse =
                simplePriceChfResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.chf;
            break;
          case "CLP":
            SimplePriceClpResponse simplePriceLocalResponse =
                simplePriceClpResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.clp;
            break;
          case "CNY":
            SimplePriceCnyResponse simplePriceLocalResponse =
                simplePriceCnyResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.cny;
            break;
          case "CZK":
            SimplePriceCzkResponse simplePriceLocalResponse =
                simplePriceCzkResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.czk;
            break;
          case "DKK":
            SimplePriceDkkResponse simplePriceLocalResponse =
                simplePriceDkkResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.dkk;
            break;
          case "EUR":
            SimplePriceEurResponse simplePriceLocalResponse =
                simplePriceEurResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.eur;
            break;
          case "GBP":
            SimplePriceGbpResponse simplePriceLocalResponse =
                simplePriceGbpResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.gbp;
            break;
          case "HKD":
            SimplePriceHkdResponse simplePriceLocalResponse =
                simplePriceHkdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.hkd;
            break;
          case "HUF":
            SimplePriceHufResponse simplePriceLocalResponse =
                simplePriceHufResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.huf;
            break;
          case "IDR":
            SimplePriceIdrResponse simplePriceLocalResponse =
                simplePriceIdrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.idr;
            break;
          case "ILS":
            SimplePriceIlsResponse simplePriceLocalResponse =
                simplePriceIlsResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.ils;
            break;
          case "INR":
            SimplePriceInrResponse simplePriceLocalResponse =
                simplePriceInrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.inr;
            break;
          case "JPY":
            SimplePriceJpyResponse simplePriceLocalResponse =
                simplePriceJpyResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.jpy;
            break;
          case "KRW":
            SimplePriceKrwResponse simplePriceLocalResponse =
                simplePriceKrwResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.krw;
            break;
          case "KWD":
            SimplePriceKwdResponse simplePriceLocalResponse =
                simplePriceKwdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.kwd;
            break;
          case "MXN":
            SimplePriceMxnResponse simplePriceLocalResponse =
                simplePriceMxnResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.mxn;
            break;
          case "MYR":
            SimplePriceMyrResponse simplePriceLocalResponse =
                simplePriceMyrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.myr;
            break;
          case "NOK":
            SimplePriceNokResponse simplePriceLocalResponse =
                simplePriceNokResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.nok;
            break;
          case "NZD":
            SimplePriceNzdResponse simplePriceLocalResponse =
                simplePriceNzdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.nzd;
            break;
          case "PHP":
            SimplePricePhpResponse simplePriceLocalResponse =
                simplePricePhpResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.php;
            break;
          case "PKR":
            SimplePricePkrResponse simplePriceLocalResponse =
                simplePricePkrResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.pkr;
            break;
          case "PLN":
            SimplePricePlnResponse simplePriceLocalResponse =
                simplePricePlnResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.pln;
            break;
          case "RUB":
            SimplePriceRubResponse simplePriceLocalResponse =
                simplePriceRubResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.rub;
            break;
          case "SAR":
            SimplePriceSarResponse simplePriceLocalResponse =
                simplePriceSarResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.sar;
            break;
          case "SEK":
            SimplePriceSekResponse simplePriceLocalResponse =
                simplePriceSekResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.sek;
            break;
          case "SGD":
            SimplePriceSgdResponse simplePriceLocalResponse =
                simplePriceSgdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.sgd;
            break;
          case "THB":
            SimplePriceThbResponse simplePriceLocalResponse =
                simplePriceThbResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.thb;
            break;
          case "TRY":
            SimplePriceTryResponse simplePriceLocalResponse =
                simplePriceTryResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.tryl;
            break;
          case "TWD":
            SimplePriceTwdResponse simplePriceLocalResponse =
                simplePriceTwdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.twd;
            break;
          case "AED":
            SimplePriceAedResponse simplePriceLocalResponse =
                simplePriceAedResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.aed;
            break;
          case "ZAR":
            SimplePriceZarResponse simplePriceLocalResponse =
                simplePriceZarResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.zar;
            break;
          case "USD":
          default:
            SimplePriceUsdResponse simplePriceLocalResponse =
                simplePriceUsdResponseFromJson(reply);
            simplePriceResponse.localCurrencyPrice =
                simplePriceLocalResponse.bismuth.usd;
            break;
        }
      }
      // Post to callbacks
      EventTaxiImpl.singleton().fire(PriceEvent(response: simplePriceResponse));
    } catch (e) {} finally {
      httpClient.close();
    }
    simplePriceResponse.localCurrencyPrice = 0;
    simplePriceResponse.btcPrice = 0;
    EventTaxiImpl.singleton().fire(PriceEvent(response: simplePriceResponse));
    return simplePriceResponse;
  }
}