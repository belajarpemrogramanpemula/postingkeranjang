import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tokoonline/constans.dart';
import 'package:tokoonline/helper/dbhelper.dart';
import 'package:tokoonline/login.dart';
import 'package:tokoonline/models/keranjang.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class KeranjangPage extends StatefulWidget {
  @override
  _KeranjangPageState createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  DbHelper dbHelper = DbHelper();
  List<Keranjang> keranjanglist = [];
  int _subTotal = 0;
  bool login = false;
  String userid = "";

  @override
  void initState() {
    super.initState();
    getkeranjang();
    cekLogin();
  }

  cekLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      login = prefs.getBool('login') ?? false;
      userid = prefs.getString('username') ?? "";
    });
  }
  
  Future<List<Keranjang>> getkeranjang() async {
    final Future<Database> dbFuture = dbHelper.initDb();
    dbFuture.then((database) {
      Future<List<Keranjang>> listFuture = dbHelper.getkeranjang();
      listFuture.then((_keranjanglist) {
        if (mounted) {
          setState(() {
            keranjanglist = _keranjanglist;
          });
        }
      });
    });
    int subtotal = 0;
    for (int i = 0; i < keranjanglist.length; i++) {
      if (keranjanglist[i].hargax.trim() != "0") {
        subtotal +=
            keranjanglist[i].jumlah * int.parse(keranjanglist[i].hargax.trim());
      }
    }
    setState(() {
      _subTotal = subtotal;
    });
    return keranjanglist;
  }


  loadingProses(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        });
  }

  _klikCekout(List<Keranjang> _keranjang) async {
    loadingProses(context);
    var params = "/klikbayar";
    var body = {"listkeranjang": json.encode(_keranjang)};
    try {
      http.post(Palette.sUrl + params, body: body).then((response) {
        var res = response.body.toString();
        if (res == "OK") {
          Navigator.of(context).pop();
          _kosongkanKeranjang();
          // Navigator.of(context).pushNamedAndRemoveUntil(
          //     '/terimakasih', (Route<dynamic> route) => false);
        }
      });
    } catch (e) {}
    return params;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang'),
      ),
      body: keranjanglist.isEmpty ? _keranjangKosong() : _widgetKeranjang(),
      bottomNavigationBar: Visibility(
        visible: keranjanglist.isEmpty ? false : true,
        child: BottomAppBar(
          color: Colors.transparent,
          child: Container(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 5.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: TextStyle(fontSize: 14.0)),
                        Text(
                            'Rp. ' +
                                NumberFormat.currency(
                                        locale: 'ID',
                                        symbol: "",
                                        decimalDigits: 0)
                                    .format(_subTotal)
                                    .toString(),
                            style:
                                TextStyle(color: Colors.red, fontSize: 18.0)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      login
                          ? _klikCekout(keranjanglist)
                          : Navigator.of(context).push(MaterialPageRoute<Null>(
                              builder: (BuildContext context) {
                              return new Login();
                            }));
                    },
                    child: Container(
                      height: 40.0,
                      child: Center(
                        child: Text('Cek Out',
                            style: TextStyle(color: Colors.white)),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(color: Colors.blue, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            height: 70.0,
            padding:
                EdgeInsets.only(left: 10.0, right: 10.0, top: 2.0, bottom: 2.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(color: Colors.grey[100], spreadRadius: 1),
              ],
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  _tambahJmlKeranjang(int id) async {
    Database db = await dbHelper.database;
    var batch = db.batch();
    db.execute('update keranjang set jumlah=jumlah+1 where id=?', [id]);
    await batch.commit();
  }

  _kurangJmlKeranjang(int id) async {
    Database db = await dbHelper.database;
    var batch = db.batch();
    db.execute('update keranjang set jumlah=jumlah-1 where id=?', [id]);
    await batch.commit();
  }

  _deleteKeranjang(int id) async {
    Database db = await dbHelper.database;
    var batch = db.batch();
    db.execute('delete from keranjang where id=?', [id]);
    await batch.commit();
  }

  _kosongkanKeranjang() async {
    Database db = await dbHelper.database;
    var batch = db.batch();
    db.execute('delete from keranjang');
    await batch.commit();
  }

  Widget _keranjangKosong() {
    return FutureBuilder(
      future: Future.delayed(Duration(seconds: 1)),
      builder: (c, s) => s.connectionState == ConnectionState.done
          ? keranjanglist.isEmpty
              ? SafeArea(
                  child: new Container(
                    color: Colors.white,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Center(
                            child: Container(
                                padding:
                                    EdgeInsets.only(left: 25.0, right: 25.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Keranjang Kosong',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                )),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: CircularProgressIndicator(),
                )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }


  Widget _widgetKeranjang() {
    return SafeArea(
      child: new Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Expanded(
              child: FutureBuilder<List<Keranjang>>(
                future: getkeranjang(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return Center(child: CircularProgressIndicator());


                  return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, i) {
                      return Container(
                        height: 110.0,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300],
                              width: 1.0,
                            ),
                          ),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.white, spreadRadius: 1),
                          ],
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.only(
                              left: 10.0, right: 10.0, top: 10.0, bottom: 10.0),
                          title: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Image.network(
                                  Palette.sUrl +"/"+ snapshot.data[i].thumbnail,
                                  height: 110.0,
                                  width: 110.0,
                                ),
                                Expanded(
                                  child: Container(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(snapshot.data[i].judul,
                                            style: TextStyle(fontSize: 16.0)),
                                        Text(snapshot.data[i].harga,
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 14.0)),
                                        Row(
                                          children: <Widget>[
                                            Container(
                                              height: 30,
                                              width: 100,
                                              margin:
                                                  EdgeInsets.only(top: 10.0),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: Colors.grey)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: <Widget>[
                                                  InkWell(
                                                    onTap: () {
                                                      if (snapshot
                                                              .data[i].jumlah >
                                                          1) {
                                                        _kurangJmlKeranjang(
                                                            snapshot
                                                                .data[i].id);
                                                      }
                                                    },
                                                    child: Icon(
                                                      Icons.remove,
                                                      color: Colors.green,
                                                      size: 22,
                                                    ),
                                                  ),
                                                  Text(
                                                    snapshot.data[i].jumlah
                                                        .toString(),
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 14.0),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      _tambahJmlKeranjang(
                                                          snapshot.data[i].id);
                                                    },
                                                    child: Icon(
                                                      Icons.add,
                                                      color: Colors.green,
                                                      size: 22,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                margin:
                                                    EdgeInsets.only(top: 10.0),
                                                padding: EdgeInsets.only(
                                                    right: 10.0,
                                                    top: 7.0,
                                                    bottom: 5.0),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: InkWell(
                                                    onTap: () {
                                                      _deleteKeranjang(
                                                          snapshot.data[i].id);
                                                    },
                                                    child: Container(
                                                      height: 25,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(2),
                                                        border: Border.all(
                                                            color: Colors.red),
                                                        boxShadow: [
                                                          BoxShadow(
                                                              color: Colors.red,
                                                              spreadRadius: 1),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        Icons.delete,
                                                        color: Colors.white,
                                                        size: 22,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {},
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
