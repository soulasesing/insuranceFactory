// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./OperacionesBasicas.sol";
import "./ERC20.sol";


//contrato para la compañia de seguro
contract InsuranceFactory is OperacionesBasicas{


    constructor () public{
        token = new ERC20Basic(100);
        Insurance = address(this);
        Aseguradora = msg.sender;

    }
   

    struct  cliente {
        address DireccionClientes;
        bool AutorizacionCliente;
        address DireccionContrato;

    }

    struct servicio {
        string  nombreServicio;
        uint precioServicioToken;
        bool  EstadoServicio;
    }

     struct lab {

         address direccionContratoLab;
         bool ValidacionLab;

    }

   
     //instancia del contrato token 
    ERC20Basic private token;

    //declaracion de la direcciones
    address Insurance;
    address payable public Aseguradora;

    
    //mapeos  para clientes, servicios y laboratorio
    mapping(address => cliente) public MappingAsegurados;
    mapping(string => servicio) public MappingServicio;
    mapping(address => lab) public MappingLab;

    //Arrays para guardar clientes, servicios y laboratorios
    address [] DireccionesAsegurados;
    string [] private nombreServicios;
    address [] DireccionesLaboratorios;


    //Modificadores y restriciones sobre asegurados y aseguradaras
    function FuncionUnicamenteSegurado(address _direccionAsegurado) public view{
        require (MappingAsegurados[_direccionAsegurado].AutorizacionCliente == true, "Direccion de asegurada NO Autorizada");
    }

    modifier UnicamanteAsegurado(address _direccionAsegurado){
          FuncionUnicamenteSegurado(_direccionAsegurado);
          _;
    }

    modifier UnicamenteAseguradora(address _direccionAseguradora){
            require(Aseguradora  ==  _direccionAseguradora, "Direccion de Aseguradora NO Autorizada");
            _;
        }
    modifier Asegurado_o_Aseguradora(address _direccionAsegurado, address _direccionEntrante){
            require ((MappingAsegurados[_direccionEntrante].AutorizacionCliente == true && _direccionAsegurado == _direccionEntrante) || Aseguradora == _direccionEntrante, "Solamente compañias de seguro o Asegurados");
        
            _;
        }

    

    //Eventos
    event EventoComprado(uint256);
    event EventoServicioProporcionado(address, string, uint256);
    event EventoLaboratorioCreado(address, address);
    event EventoAseguradoCreado(address, address);
    event EventoBajaAsegurado(address);
    event EventoServicioCreado(string, uint256);
    event EventoBajaServicio(string);
  
    //Funcion para Crear un contrato por un laboratorio
    function creacionLab() public {
    DireccionesLaboratorios.push(msg.sender);
    address direccionLab = address(new Laboratorio(msg.sender, Insurance));
    MappingLab[msg.sender] = lab(direccionLab, true);
    emit EventoLaboratorioCreado(msg.sender, direccionLab);
    
    
    }

    //Funcion para Crear un contrato de un Asegurado
    function creacionContratoAsegurado() public {
        DireccionesAsegurados.push(msg.sender);
        address direccionAsegurado= address(new InsuranceHealthRecord(msg.sender,token, Insurance, Aseguradora));
        MappingAsegurados[msg.sender] = cliente(msg.sender, true, direccionAsegurado);
        emit EventoAseguradoCreado(msg.sender, direccionAsegurado);

    }
    ////FUNCION PARA DEVOLVER EL ARRAY DE LABORATORIO
    function Laboratorios() public view UnicamenteAseguradora(msg.sender) returns( address [] memory){
        return DireccionesLaboratorios;
    }
    ////FUNCION PARA DEVOLVER EL ARRAY DE ASEGURADOS
    function Asegurados() public view UnicamenteAseguradora(msg.sender) returns(address [] memory){
        return DireccionesAsegurados;
     } 

     //funcion para devolver el historial de una asegurado
    function consultarHistorialAsegurados(address _direccionAsegurado, address _direccionConsultor) public view Asegurado_o_Aseguradora(_direccionAsegurado, _direccionConsultor) returns(string memory){
        string memory historial = "";
        address direccionContratoAsegurado = MappingAsegurados[_direccionAsegurado].DireccionContrato;
        for(uint256 i = 0; i< nombreServicios.length; i++){
            if(MappingServicio[nombreServicios[i]].EstadoServicio && InsuranceHealthRecord(direccionContratoAsegurado).ServicioEstadoAsegurado(nombreServicios[i])==true){
                 (string memory nombreServicio, uint256 precioServicio) = InsuranceHealthRecord(direccionContratoAsegurado).HistorialAsegurado(nombreServicios[i]);
                 historial = string(abi.encodePacked(historial, "(", nombreServicio, ", ", uint2str(precioServicio), ") -----------"));

            }

        }

        return historial;

    }

    //DAR DE BAJA A UN CLIENTE
    function darBajaCliente(address _direccionAsegurado) public  UnicamenteAseguradora(msg.sender)returns(string memory){
        MappingAsegurados[_direccionAsegurado].AutorizacionCliente = false;
        InsuranceHealthRecord(MappingAsegurados[_direccionAsegurado].DireccionContrato).darBaja;
        emit EventoBajaAsegurado(_direccionAsegurado);

    }

    function nuevoServicio(string memory _nombreServicio, uint256 _precioServicio) public UnicamenteAseguradora(msg.sender){
        MappingServicio[_nombreServicio] = servicio(_nombreServicio, _precioServicio, true);
        nombreServicios.push(_nombreServicio);
        emit EventoServicioCreado(_nombreServicio, _precioServicio);

    }

    function darBajaServicio(string memory _nombreServicio) public UnicamenteAseguradora(msg.sender){
        require(ServicioEstado(_nombreServicio)== true, "No se ha dado de alta");
        MappingServicio[_nombreServicio].EstadoServicio= false;
        emit EventoBajaServicio(_nombreServicio);
        
    }
    function ServicioEstado(string memory _nombreServicio) public view returns (bool){
        return MappingServicio[_nombreServicio].EstadoServicio;
    }
     function getPrecioServicio(string memory _nombreServicio) public view returns (uint256 tokens){
           require(ServicioEstado(_nombreServicio)== true, "Servicio no diponible ");
           return MappingServicio[_nombreServicio].precioServicioToken;
     }

    function ConsultarServiciosActivos() public view returns (string [] memory){
        string  [] memory ServiciosActivos = new string[](nombreServicios.length);
        uint256 contador= 0;
        for (uint256 i =0; i < nombreServicios.length; i++){
            if(ServicioEstado(nombreServicios[i]) == true){
                   ServiciosActivos[contador] = nombreServicios[i];
                   contador ++; 

            }
        }
        return ServiciosActivos;


    }
    function compraTokens(address _asegurado, uint256 _numTokens) public payable UnicamanteAsegurado(_asegurado){
        uint Balance = balanceOf();

        require(_numTokens <= Balance,"compra un nro de token inferior");
        require(_numTokens > 0,"el valos debe ser mayor de 0");

        token.transfer(msg.sender, _numTokens);
        emit EventoComprado(_numTokens);

    }
    //consulta el balance de la aseguradora
    function balanceOf() public view  returns(uint256 tokens){
        return (token.balanceOf(address(Insurance)));

    }
    //para aumentar la cantidad de token
    function generarToken(uint256 _numTokens) public UnicamenteAseguradora(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }




}

contract InsuranceHealthRecord is OperacionesBasicas {

    enum Estado {alta, baja}

    struct Owner{
        address direccionPropietario;
        uint256 saldoPropietario;
        Estado  estado;
        IERC20 tokens;
        address insurance;
        address payable aseguradora;

    }

    Owner propietario;

    constructor(address _owner,IERC20 _token, address _insurance, address payable _aseguradora) public{
        propietario.direccionPropietario = _owner;
        propietario.saldoPropietario = 0;
        propietario.estado = Estado.alta;
        propietario.tokens = _token;
        propietario.insurance = _insurance;
        propietario.aseguradora =_aseguradora;
     
    }
    struct ServiciosSolicitados{
        string nombreServicio;
        uint256 precioServicio;
        bool estadoServicio;

    }
    struct ServiciosSolicitadosLab{

        string nombreServicio;
        uint256 precioServicio;
        address direccionLab;
        
    }

     //EVENTOS
     
     event EventoSelfDestruct(address);
     event EventoDevolverTokens(address, uint256);
     event EventoServicioPagado(address, string, uint256);
     event EventoPeticionServicioLab(address, address, string);

   

    mapping (string => ServiciosSolicitados) historialAsegurados;
    ServiciosSolicitadosLab [] historialAseguradosLaboratorio;
    
   
    modifier Unicamente(address _direccion){
        require(_direccion == propietario.direccionPropietario, "No eres el asegurado de la poliza.");
            _;
    }

   

    function HistorialAseguradosLaboratorio() public view returns(ServiciosSolicitadosLab [] memory){
        return historialAseguradosLaboratorio;
    }

    function HistorialAsegurado(string memory _servicio) public view returns (string memory nombreServicio, uint256 precioServicio){
        return(historialAsegurados[_servicio].nombreServicio, historialAsegurados[_servicio].precioServicio);
    }

    function ServicioEstadoAsegurado(string memory _servicio) public view returns (bool){
        return historialAsegurados[_servicio].estadoServicio;
    }
    function darBaja() public Unicamente(msg.sender){
        emit EventoSelfDestruct(msg.sender);
        selfdestruct(msg.sender);

    }

    function CompraTokens (uint256 _numTokens) payable public Unicamente(msg.sender){
        require(_numTokens > 0, "Debes comprar un nro de token mayor a 0");
        uint256 coste = calcularPrecioTokens(_numTokens);
        require(msg.value >= coste, "no tiene suficiente ethers");
        uint256 returnValue = msg.value - coste;
        msg.sender.transfer(returnValue);
        InsuranceFactory(propietario.insurance).compraTokens(msg.sender, _numTokens);
    }

    function balanceOf() public view Unicamente(msg.sender) returns (uint _balance){
        return (propietario.tokens.balanceOf(address(this)));
    }

    function devolverTokens(uint256 _numTokens) public payable  Unicamente(msg.sender){
        require(_numTokens > 0, "no tienes suficiente tokens");
        require(_numTokens <= balanceOf(), "NO tienes los tockens suficientes para devolver");
        propietario.tokens.transfer(propietario.aseguradora, _numTokens);
        msg.sender.transfer(calcularPrecioTokens(_numTokens));
        emit EventoDevolverTokens(msg.sender, _numTokens);

    }

    function peticionServicio(string memory _servicio) public Unicamente(msg.sender){
        // Se comprueba que el servicio esté dado de alta
        require(InsuranceFactory(propietario.insurance).ServicioEstado(_servicio)== true, "el servicio no esta dado de alta en la aseguradora");
        // Se obtiene el precio del servicio a partir del otro contrato IF
        uint256 pagoTokens = InsuranceFactory(propietario.insurance).getPrecioServicio(_servicio);
         // Es necesario que el precio del servicio sea menor al número de tokens de lo dispuesto
        require (pagoTokens <= balanceOf(), "Necesitas mas tocken para optar por este servicio");
        // Se envían los tokens que vale el servicio a la aseguradora (persona)
        propietario.tokens.transfer(propietario.aseguradora, pagoTokens);
         // Relacion con el nombre del nuevo servicio y la estructura definida de los servicios solicitados
        historialAsegurados[_servicio] = ServiciosSolicitados(_servicio, pagoTokens, true);
         // Evento para avisar de que el servicio se ha pagado
        emit EventoServicioPagado(msg.sender, _servicio, pagoTokens);

    }

    function peticionServicioLab(address _direccionLab, string memory _servicio) public  payable Unicamente(msg.sender){
        Laboratorio contratoLab = Laboratorio(_direccionLab);
        require(msg.value == contratoLab.ConsultarPrecioServicio(_servicio)* 1 ether, "Operacion Invalida");
        contratoLab.DarServicio(msg.sender, _servicio);
        payable(contratoLab.DireccionLab()).transfer(contratoLab.ConsultarPrecioServicio(_servicio)* 1 ether);
        historialAseguradosLaboratorio.push(ServiciosSolicitadosLab(_servicio, contratoLab.ConsultarPrecioServicio(_servicio), _direccionLab));
        emit EventoPeticionServicioLab(_direccionLab, msg.sender,  _servicio);
    }

       // Funcion para ver el historial de los servicios de la aseguradora que ha consumido el asegurado
   function HistorialAseguradora() public view Unicamente(msg.sender) returns(string memory) {
        return InsuranceFactory(propietario.insurance).consultarHistorialAsegurados(msg.sender, msg.sender);
    }

}

contract Laboratorio is OperacionesBasicas{


        address public DireccionLab;
        address contratoAseguradora;

        constructor (address _account, address _direccionContratoAseguradora) public {
            DireccionLab = _account;
            contratoAseguradora = _direccionContratoAseguradora;
    }

        mapping (address => string) public ServicioSolicitado;

        address [] public PeticionesServicios;

        mapping (address => ResultadoServicio) ResultadatosServiciosLab;

        struct ResultadoServicio{
            string diagnostico_servicio;
            string codigo_IPFS;
        }
        string [] nombreServicioLab;

        mapping(string => ServicioLab) public servicioLab;

        struct ServicioLab{
            string nombreServicio;
            uint256 precio;
            bool enFuncionamiento;
        }

        //Eventos
        event EventoServicioFuncionanado(string, uint256);
        event EventoDarServicio(address, string);

        modifier UnicamenteLab(address _direccion){
            require(_direccion == DireccionLab, "no existen permisos en el sistema para ejecutar esta función ");
            _;
        }


    function NuevoServicioLab(string memory _servicio, uint256 _precio) public UnicamenteLab(msg.sender){
        servicioLab[_servicio] = ServicioLab(_servicio, _precio, true);
        nombreServicioLab.push(_servicio);
        emit EventoServicioFuncionanado(_servicio, _precio);
    }


    function ConsultarServicios() public view returns(string[] memory){
        return nombreServicioLab;
    }


    
    function ConsultarPrecioServicio(string memory _servicio) public view returns(uint256){
        return  servicioLab[_servicio].precio;

    }
    
    function DarServicio(address _direccionAsegurado, string memory _servicio) public{
        InsuranceFactory IF = InsuranceFactory(contratoAseguradora);
        IF.FuncionUnicamenteSegurado(_direccionAsegurado);
        require(servicioLab[_servicio].enFuncionamiento == true, "El servicio no esta disponible actualmente.");
        ServicioSolicitado[_direccionAsegurado] = _servicio;
        PeticionesServicios.push(_direccionAsegurado);
        emit EventoDarServicio(_direccionAsegurado, _servicio);

    }

    function DarResultados(address _direccionAsegurado, string memory _diagnostico, string memory _codigoIPFS) public UnicamenteLab(msg.sender){
        ResultadatosServiciosLab[_direccionAsegurado] = ResultadoServicio(_diagnostico, _codigoIPFS);
        }

    function visualizarResultados(address _direccionAsegurado) public view returns(string memory _diagnostico, string memory _codigoIPFS){
        _diagnostico = ResultadatosServiciosLab[_direccionAsegurado].diagnostico_servicio;
        _codigoIPFS = ResultadatosServiciosLab[_direccionAsegurado].codigo_IPFS;


    }



}