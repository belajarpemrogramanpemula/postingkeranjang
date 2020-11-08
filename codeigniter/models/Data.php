<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Data extends CI_Model {
	public function login($username,$password){
		$data=$this->db->query("select * from signin where userid='".$username."' and pass='".$password."'");
		$this->db->close();
		return $data->result();
	}
	public function cabangbyuserid($userid){
		$data=$this->db->query("select * from cabang where userid='".$userid."'");
		$this->db->close();
		return $data->result();
	}
	public function pelangganbyuserid($userid){
		$data=$this->db->query("select * from pelanggan where userid='".$userid."'");
		$this->db->close();
		return $data->result();
	}

}
