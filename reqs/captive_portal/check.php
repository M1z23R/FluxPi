<?php
	require_once("authenticator.php");

	switch ($candidate_code) {
		# case "1": header("Location:error.html"); break;
		case "2": header("Location:final.html"); break;
		default: header("Location:error.html"); break;
	}
