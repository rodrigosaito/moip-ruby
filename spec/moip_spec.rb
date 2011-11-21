# encoding: utf-8
require "moip"
require "digest/sha1"

MoIP::Client
MoIP::DirectPayment

describe "Make payments with the MoIP API" do

  before :all do

    @pagador = {:nome => "Luiz Inácio Lula da Silva",
                :login_moip => "lula",
                :email => "presidente@planalto.gov.br",
                :tel_cel => "(61)9999-9999",
                :apelido => "Lula",
                :identidade => "111.111.111-11",
                :logradouro => "Praça dos Três Poderes",
                :numero => "0",
                :complemento => "Palácio do Planalto",
                :bairro => "Zona Cívico-Administrativa",
                :cidade => "Brasília",
                :estado => "DF",
                :pais => "BRA",
                :cep => "70100-000",
                :tel_fixo => "(61)3211-1221" }

    @receiver = {:login_moip => "moip-ruby", :apelido => "moip_ruby"}

    @billet_without_razao = { :valor => "8.90", :id_proprio => "qualquer_um",
                              :forma => "BoletoBancario", :pagador => @pagador}

    @billet = { :valor => "8.90", :id_proprio => "qualquer_um",
                :forma => "BoletoBancario", :pagador => @pagador ,
                :razao=> "Pagamento" }

    @comissionamento = {:razao => "Quero um pouco tambem.",
                        :valor_percentual => "10%",
                        :valor_fixo => "100",
                        :mostrar_para_pagador => false,
                        :login_moip => "moleza" }

    @billet_with_comission = { :valor => "8.90", :id_proprio => "qualquer um", :forma => "BoletoBancario",
                               :pagador => @pagador , :razao=> "Pagamento", :comissoes => @comissionamento }


    @debit = { :valor => "8.90", :id_proprio => "qualquer_um", :forma => "DebitoBancario",
               :instituicao => "BancoDoBrasil", :pagador => @pagador,
               :razao => "Pagamento"}

    @credit = { :valor => "8.90", :id_proprio => "qualquer_um", :forma => "CartaoCredito",
                :instituicao => "AmericanExpress",:numero => "345678901234564",
                :expiracao => "08/11", :codigo_seguranca => "1234",
                :nome => "João Silva", :identidade => "134.277.017.00",
                :telefone => "(21)9208-0547", :data_nascimento => "25/10/1980",
                :parcelas => "2", :recebimento => "AVista",
                :pagador => @pagador, :razao => "Pagamento"}

  end

  context "misconfigured" do
    it "should raise a missing config error " do
      MoIP.setup do |config|
        config.uri = 'https://desenvolvedor.moip.com.br/sandbox'
        config.token = nil
        config.key = nil
      end

      MoIP::Client # for autoload
      lambda { MoIP::Client.checkout(@billet) }.should raise_error(MoIP::MissingConfigError)
    end

    it "should raise a missing token error when token is nil" do
      MoIP.setup do |config|
        config.uri = 'https://desenvolvedor.moip.com.br/sandbox'
        config.token = nil
        config.key = 'key'
      end

      MoIP::Client # for autoload
      lambda { MoIP::Client.checkout(@billet) }.should raise_error(MoIP::MissingTokenError)
    end

    it "should raise a missing key error when key is nil" do

      MoIP.setup do |config|
        config.uri = 'https://desenvolvedor.moip.com.br/sandbox'
        config.token = 'token'
        config.key = nil
      end

      MoIP::Client # for autoload
      lambda { MoIP::Client.checkout(@billet) }.should raise_error(MoIP::MissingKeyError)
    end



    it "should raise a missing token error when token is empty" do
      MoIP.setup do |config|
        config.uri = 'https://desenvolvedor.moip.com.br/sandbox'
        config.token = ''
        config.key = 'key'
      end

      MoIP::Client # for autoload
      lambda { MoIP::Client.checkout(@billet) }.should raise_error(MoIP::MissingTokenError)
    end

    it "should raise a missing key error when key is empty" do

      MoIP.setup do |config|
        config.uri = 'https://desenvolvedor.moip.com.br/sandbox'
        config.token = 'token'
        config.key = ''
      end

      MoIP::Client # for autoload
      lambda { MoIP::Client.checkout(@billet) }.should raise_error(MoIP::MissingKeyError)
    end
  end

  context "validations" do


    before(:each) do
      MoIP.setup do |config|
        config.uri = 'https://desenvolvedor.moip.com.br/sandbox'
        config.token = 'token'
        config.key = 'key'
      end
    end
    it "should raise invalid phone" do
      @data = @credit.merge({:pagador => {:tel_fixo => 'InvalidPhone', :tel_cel => "(61)9999-9999"}})
      lambda { MoIP::Client.checkout(@data) }.should raise_error(MoIP::InvalidPhone)
    end
    it "should raise invalid cellphone" do
      @data = @credit.merge({:pagador => {:tel_cel => 'InvalidCellphone', :tel_fixo => "(61)9999-9999"}})
      lambda { MoIP::Client.checkout(@data) }.should raise_error(MoIP::InvalidCellphone)
    end
    it "should raise invalid expiry" do
      @data = @credit.merge({:expiracao => 'InvalidExpiry'})
      lambda { MoIP::Client.checkout(@data) }.should raise_error(MoIP::InvalidExpiry)
    end
    it "should raise missing birthdate" do
      @data = @credit.merge({:data_nascimento => nil})
      lambda { MoIP::Client.checkout(@data) }.should raise_error(MoIP::MissingBirthdate)
    end
    it "should raise invalid institution error" do
      @data = @credit.merge({:instituicao => 'InvalidInstitution'})
      lambda { MoIP::Client.checkout(@data) }.should raise_error(MoIP::InvalidInstitution)
    end
    it "should raise invalid receiving error" do
      @data = @credit.merge({:recebimento => 'InvalidReceiving'})
      lambda { MoIP::Client.checkout(@data) }.should raise_error(MoIP::InvalidReceiving)
    end
    it "should raise invalid value error if 0" do
      @credit[:valor] = 0
      lambda { MoIP::Client.checkout(@credit) }.should raise_error(MoIP::InvalidValue)
    end
    it "should raise invalid value error if '0'" do
      @credit[:valor] = '0'
      lambda { MoIP::Client.checkout(@credit) }.should raise_error(MoIP::InvalidValue)
    end
    it "should raise invalid value error if 0.0" do
      @credit[:valor] = 0.0
      lambda { MoIP::Client.checkout(@credit) }.should raise_error(MoIP::InvalidValue)
    end
    it "should raise invalid value error if '0.0'" do
      @credit[:valor] = '0.0'
      lambda { MoIP::Client.checkout(@credit) }.should raise_error(MoIP::InvalidValue)
    end
    it "should raise invalid value error if -1" do
      @credit[:valor] = -1
      lambda { MoIP::Client.checkout(@credit) }.should raise_error(MoIP::InvalidValue)
    end

    it "should have a fixed comission of $100" do
      @billet_with_comission[:comissoes][:valor_fixo].should eql "100"
    end
  end
end
