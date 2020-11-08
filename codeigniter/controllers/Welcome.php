<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Welcome extends CI_Controller {
	function __construct(){
		parent::__construct();
		$this->load->model("data");
	}

	function genNota($n,$kode){
		$has="";
		$lbr=strlen($n);
		for($i=1;$i<=4-$lbr;$i++){
			$has=$has."0";
		}
		return date("Y").date("m").date("d")."/".$has.$n.$kode;
	}

	public function index(){
		$this->load->view('welcome_message');
	}
	public function pages($judul=''){
		}else if($judul=="login"){
			$sData = array();
			$status = "OK";
			$sData = array(
				"response_status"=>$status,
				"response_message"=>'',
				"data"=>array()
			);
			$username=$this->input->get('username');
			$password=$this->input->get('password');
			$data=$this->data->login($username,$password);
			if($data){
				foreach($data as $rs){
					$arr_row=array();
					$arr_row['username'] = $rs->userid;
					$arr_row['nama'] = $rs->nama;
					$arr_row['email'] = $rs->email."";
					$arr_row['level'] = $rs->level."";
					$arr_row['foto'] = $rs->foto."";
					if($rs->level=="2"){
						$datax=$this->data->cabangbyuserid($username);
						if($datax){
							foreach($datax as $rsx){
								$arr_row['alamat'] = $rsx->alamat."";
								$arr_row['kota'] = $rsx->kota."";
								$arr_row['telp'] = $rsx->telp."";
							}
						}
					}else if($rs->level=="3"){
						$datax=$this->data->pelangganbyuserid($username);
						if($datax){
							foreach($datax as $rsx){
								$arr_row['alamat'] = $rsx->alamat."";
								$arr_row['kota'] = $rsx->kota."";
								$arr_row['telp'] = $rsx->telp."";
							}
						}
					}
					$sData['data'][] = $arr_row;
				}
			}else{
				$sData['response_status']= "Error";
				$sData['response_message']= "Password Salah";
			}
			header('Content-Type: application/json');
			echo json_encode($sData, JSON_PRETTY_PRINT);
		}else if($judul=="klikbayar"){
			$query = $this->db->query("select jual from conter");
			$row = $query->result();
			$nota = $this->genNota($row[0]->jual,"J");
			$query = $this->db->query("update conter set jual=jual+1");

			$total=0;
			$keterangan="";
			$userid="";
			$idcabang="";
			$token="";
			$email="";
			$nama="";
			//$keranjang=json_decode($this->input->post('body'));
			$listkeranjang=json_decode($this->input->post('listkeranjang'));
			foreach ($listkeranjang as $key => $rs) {
				//echo $rs->id." ".$rs->idproduk." ".$rs->judul." ".$rs->harga." ".$rs->hargax." ".$rs->thumbnail." ".$rs->jumlah." ".$rs->userid."<br>\n";

				$this->db->query("insert into penjualan(nota,tanggal,idproduk,judul,harga,jumlah,thumbnail,userid,idcabang)
				values('".$nota."','".date("Y-m-d H:i:s")."','".$rs->idproduk."','".$rs->judul."','".$rs->hargax."','".$rs->jumlah."',
				'".$rs->thumbnail."','".$rs->userid."','".$rs->idcabang."')");
				
			}
			echo "OK";

		}
	}

}
