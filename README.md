# ConvertToCoreKata
Basic Kata for converting a VS 2015 / .NET Framework project and solution to VS 2017 / .NET Core

**Note:** This repo contains a [solution](https://github.com/nickfloyd/ConvertToCoreKata/commits/solution) branch of the code that will help you as you work your way through the kata.

###Kata Success

You are able to open up and build the solution in VIsual Studio 2017 using the new csproj format.

###Kata Steps

1. Convert the solution to Visual Studio 2017 using the version: `15.0.26014.0`
2. Convert the projects to use the Visual Studio 2017 tools version: `15`
3. Delete all `Properties/AssemblyInfo.cs` files (the new build scheme takes care of all of that for you).
4. Convert the `ConvertToCoreLib.csproj` file to the new format (see below)
5. Convert the `ConvertToCore.csproj` file to the new format (see below)
6. Delete `packages.config` file

### New csproj format

**All default configuration**

```
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProjectGuid>{F17CF94D-B897-4229-9F92-A9421A474FA6}</ProjectGuid>
    <OutputType>Library</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace>ConvertToCore</RootNamespace>
    <AssemblyName>ConvertToCore</AssemblyName>
    <TargetFrameworkVersion>v4.5.1</TargetFrameworkVersion>
    <FileAlignment>512</FileAlignment>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <DebugSymbols>true</DebugSymbols>
    <DebugType>full</DebugType>
    <Optimize>false</Optimize>
    <OutputPath>bin\Debug\</OutputPath>
    <DefineConstants>DEBUG;TRACE</DefineConstants>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
    <DebugType>pdbonly</DebugType>
    <Optimize>true</Optimize>
    <OutputPath>bin\Release\</OutputPath>
    <DefineConstants>TRACE</DefineConstants>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
  </PropertyGroup>
```

**has been replaced by:**

```

<Project Sdk="Microsoft.NET.Sdk" ToolsVersion="15.0">

  <PropertyGroup>
    <TargetFramework>net451</TargetFramework>
  </PropertyGroup>
  ....
```
**All file references**

```
  <ItemGroup>
    <Compile Include="ConvertToCoreApp.cs" />
    <Compile Include="Properties\AssemblyInfo.cs" />
  </ItemGroup>
  <ItemGroup>
    <None Include="packages.config" />
  </ItemGroup>
  ...
```

**Have been replaced with**

```
  <ItemGroup>
    <Compile Include="**\*.cs" />
    <EmbeddedResource Include="**\*.resx" />
  </ItemGroup>
```

**All Package references**

```
<ItemGroup>
    <Reference Include="Newtonsoft.Json, Version=9.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed, processorArchitecture=MSIL">
      <HintPath>packages\Newtonsoft.Json.9.0.1\lib\net45\Newtonsoft.Json.dll</HintPath>
      <Private>True</Private>
    </Reference>
    <Reference Include="Serilog, Version=2.0.0.0, Culture=neutral, PublicKeyToken=24c2f752a8e58a10, processorArchitecture=MSIL">
      <HintPath>packages\Serilog.2.4.0\lib\net45\Serilog.dll</HintPath>
      <Private>True</Private>
    </Reference>
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="System.Xml.Linq" />
    <Reference Include="System.Data.DataSetExtensions" />
    <Reference Include="Microsoft.CSharp" />
    <Reference Include="System.Data" />
    <Reference Include="System.Net.Http" />
    <Reference Include="System.Xml" />
  </ItemGroup>
```

**Have been replaced with**

```
   <ItemGroup Condition="'$(TargetFramework)' == 'net451'">
      <PackageReference Include="Newtonsoft.Json" Version="9.0.1" />
      <PackageReference Include="Serilog" Version="2.4.0" />
  </ItemGroup>
```
