<?php

use Phalcon\Mvc\Controller;

class SayHiController extends Controller
{
    public function indexAction()
    {
    }
    public function sayHiAction()
    {
        return '<h1>Hi YM Good</h1>';
    }
}
