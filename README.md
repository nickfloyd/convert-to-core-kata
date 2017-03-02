# ConvertToCoreKata

**Kata** originally were teaching and training methods by which successful combat techniques were preserved and passed on. Practicing kata allowed a company of persons to engage in a struggle using a systematic approach, rather than as individuals in a disorderly manner. [source](https://en.wikipedia.org/wiki/Kata)

**NOTE: You can skip all of the Kata stuff if you'd like and simply use the [conversion script](https://github.com/nickfloyd/ConvertToCoreKata/blob/master/ConvertToCore.ps1). More details on that below.**

###Kata Definition

Basic Kata for converting a VS 2015 / .NET Framework project and solution to VS 2017 / .NET Core

###Kata Success

You are able to open up and build the solution in Visual Studio 2017 using the new csproj format.

###Kata Steps

1. Convert the solution to Visual Studio 2017 using the version: `15.0.26014.0`
2. Convert the projects to use the Visual Studio 2017 tools version: `15`
3. Delete all `Properties/AssemblyInfo.cs` files (the new build scheme takes care of all of that for you).
4. Convert the `ConvertToCoreLib.csproj` file to the new format (see below)
5. Convert the `ConvertToCore.csproj` file to the new format (see below)
6. Delete `packages.config` file

###Kata Solution

This repo contains a [solution](https://github.com/nickfloyd/ConvertToCoreKata/commits/solution) branch of the code that will help you as you work your way through the kata.


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

### csproj Conversion script

This script can be found [here](https://github.com/nickfloyd/ConvertToCoreKata/blob/master/ConvertToCore.ps1)

While we are waiting for the awesome tools team to get a completed conversion tool into Visual Studio 2017 I took a stab at writing a quick script to get the job done.

Keep in mind that you are using this at your own risk. Some things still need to be handled such as build task conversions and the like.

#### Usage

I suggest you use the super power of your version control to make sure you can iterate on your project and test the script.

This might look like:

#####(1) Create a branch for your solution

`git checkout -b core-conversion`

#####(2) Execute the script

`.\ConvertToCore.ps1 'c:\Absolute Path where your code is\'`

#####(3) Review the results

#####(4) Restore your branch

`git clean -dfx`  
`git reset --hard`

#### Options

From powershell (default)

`.\ConvertToCore.ps1 'c:\Absolute Path where your code is\'`

**Updating the solution (defaults to `$true`)**: This give you the option of updating your .sln file(s) `VisualStudioVersion` with either a specified version (using the parameter `VSSolutionVersion`) or using the default `15.0.26014.0`.

`.\ConvertToCore.ps1 'c:\Absolute Path where your code is\' $false`

**Updating the solution with a specific tooling version (defaults to `15.0.26014.0`)**

`.\ConvertToCore.ps1 'c:\Absolute Path where your code is\' $true '15.0.26014.0'`

**Removing the original project files (defaults to `$true`)**: This config option allows you to specify if you'd like the backups of the proj files to be deleted or if you'd like to keep them.

`.\ConvertToCore.ps1 'c:\Absolute Path where your code is\' $true '15.0.26014.0' $true`

