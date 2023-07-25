<?php

use Phalcon\Mvc\Controller;

class IndexController extends Controller
{
    public function indexAction()
    {
        return '<h1>Hello! Welcome to atomic php!, current time: ' . time() . '</h1>';
    }
}
