#include <cstdio>
#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <vector>
#include <dirent.h>
#include <CGAL/Cartesian_d.h>
#include <CGAL/Random.h>
#include <CGAL/Gmpq.h>
#include <CGAL/Min_sphere_of_spheres_d.h>
#include <CGAL/Min_sphere_of_spheres_d_traits_3.h>
#include <limits>
#include <Windows.h>
#define FILE_NAME "tmp_io.txt"
#define DEBUG_FILENAME "sec_debugMode.txt"
#define ANGLE_PRESISION 1
#define PI 3.14159265
#define PRECISION 10
#define RANGE_PCA_OPT 90
typedef CGAL::Cartesian_d<double>             K;
typedef CGAL::Min_sphere_of_spheres_d_traits_d<K,double,3> Traits;
typedef CGAL::Min_sphere_of_spheres_d<Traits> Min_sphere;
typedef K::Point_d                        Point;
typedef Traits::Sphere                    Sphere;

double epsilon = 0.00001;
bool debug_mode = false;
bool image_mode = false;
using namespace std;
vector<double> radiuses;


class myPoint{
	public:
		double cor[3];
		myPoint(double x ,double y ,double z){
			cor[0] = x; cor[1] = y; cor[2] = z;
		}
		myPoint(){}
		void copy(myPoint &other) {
			cor[0] = other.cor[0];
			cor[1] = other.cor[1];
			cor[2] = other.cor[2];
		}
		double getPhi() {
			double mag = sqrt(pow((cor[0]),2) + pow((cor[1]),2) + pow((cor[2]),2));
			return acos(cor[2]/mag)*(180/PI);
		}
		double getTheta() {
			if (cor[0] == 0) { return 90; }
			return atan(cor[1]/cor[0])*(180/PI);
		}
};

void readfile(string filename, vector<myPoint> &points, boolean pca_opt,double * phi_pca, double * theta_pca){
	string line;
	int numOfdots, pos;
	ifstream myfile (filename);
	if (myfile.is_open())
	{
		getline (myfile,line);
		numOfdots = atoi(line.c_str());
		points.resize(numOfdots);
		for (int i = 0; i< numOfdots; i++){
			if(! myfile.good() )
				cout << "error:  wrong number of lines in file" << endl << std::flush;
			getline (myfile,line);
			for(int j=0 ; j<3; j++){
				pos = line.find(" ");
				points[i].cor[j] = atof(line.substr(0, pos).c_str());
				line = line.substr(pos + 1);
			}
		}
		if (pca_opt)
		{
			myPoint pca_opt;
			getline (myfile,line);
			for(int j=0 ; j<3; j++){
				pos = line.find(" ");
				pca_opt.cor[j] = atof(line.substr(0, pos).c_str());
				line = line.substr(pos + 1);
			}
			*phi_pca = pca_opt.getPhi();
			*theta_pca = pca_opt.getTheta();
			//cout << "PHI: " << *phi_pca << ", THETA: " << *theta_pca << endl;
		}
		myfile.close();
	} else cout << "error:  can't open file tmp_io.txt" << endl << std::flush;
}

void calcSEC(double precision, string filename, double * radius, myPoint * secPoint, myPoint * secDirection, boolean pca_opt = false)
{
	vector<myPoint> points;
	vector<Sphere> S;
	double coord[3];
	double phi_pca, theta_pca;
	readfile(filename, points,pca_opt,&phi_pca,&theta_pca);
	*radius = 50; //todo: return to limits<double>::max();
	double thetaMax = 180.0, phiMax=180.0,theta=0,phi=0;
	if (pca_opt)
	{
		theta=theta_pca - 0.5*RANGE_PCA_OPT;
		thetaMax=theta_pca + 0.5*RANGE_PCA_OPT;
		phiMax=phi_pca + 0.5*RANGE_PCA_OPT;
	}
	for(; theta < thetaMax - epsilon; theta += precision){
		phi = (pca_opt) ? phi_pca - 0.5*RANGE_PCA_OPT : 0;
		for(; phi < phiMax - epsilon; phi += precision){ 
			S.clear();
			//project to the plane that is vertical to the vector with sigma and theta
			myPoint normal(sin(phi*PI/180)*cos(theta*PI/180), sin(phi*PI/180)*sin(theta*PI/180), cos(phi*PI/180));
			for (int i=0; i < (int)points.size(); ++i) {
				//dist = dist from the point to the plane along the normal vector
				double dist = points[i].cor[0]*normal.cor[0] + points[i].cor[1]*normal.cor[1] +
							points[i].cor[2]*normal.cor[2];
				for (int j=0; j<3; ++j)
					coord[j]= points[i].cor[j] - dist*normal.cor[j];
				Point p(3,coord,coord+3);         
				S.push_back(Sphere(p,0));
			}
			Min_sphere ms(S.begin(),S.end());       // check in the spheres
			CGAL_assertion(ms.is_valid());
			//get radius from sphere; if better, then save theta sigma radus and point
			double res = ms.radius();
			if (image_mode)
				radiuses.push_back(res);
			if (res < *radius) {
				*radius = res;
				(*secDirection).copy(normal);
				(*secPoint).cor[0] = ms.center_cartesian_begin()[0];
				(*secPoint).cor[1] = ms.center_cartesian_begin()[1];
				(*secPoint).cor[2] = ms.center_cartesian_begin()[2];
			}
		}
	}
}
void writeOutput (string infile, double * radius, myPoint * sec, myPoint * dir, string * msg)
{
	ofstream outfile;
	string outfilename(infile);
	outfilename = outfilename.substr(0,outfilename.length() - 4) + "_res.txt";
	outfile.open(outfilename, fstream::app);
	outfile.precision(PRECISION);
	if (debug_mode)
		outfile << (*msg) << endl;
	outfile << (*radius) << " " << endl;
	outfile << (*sec).cor[0] << " " << (*sec).cor[1] << " " << (*sec).cor[2] << " " << endl;
	outfile << (*dir).cor[0] << " " << (*dir).cor[1] << " " << (*dir).cor[2] << " " << endl;
	if (debug_mode)
		outfile << "arccos(x): " << acos((*dir).cor[0]) << ", arccos(z): " << acos((*dir).cor[2]) << endl;
	outfile.close();
}

bool listFiles(vector<string> * files) {
	DIR *directory;
	struct dirent *dir;
	directory = opendir(".");
	if (!directory)
		return false;
	while ((dir = readdir(directory)) != NULL)
	{
		string f(dir->d_name);
	  	if (f.length() >= 7 && ((f.substr(0,3)).compare("sec") == 0) && (f.substr(f.length() - 4)).compare(".txt") == 0)
			(*files).push_back(f);
	}
	return true;
}

void writeStatistics(string infile, double accurate, double n, string pres)
{
	ofstream outfile;
	string outfilename(DEBUG_FILENAME);
	outfilename = outfilename.substr(0,outfilename.length() - 4) + "_res.txt";
	outfile.open(outfilename, fstream::app);
	outfile.precision(PRECISION);
	outfile << "==Debug Mode==: " << infile << ": % Error " << pres << "-1 is " << (abs(accurate-n)/accurate)*100.0 << endl << endl;
	outfile.close();
}


double secDebugRoutine(string filename, double precision)
{
	myPoint secPoint, secDirection;
	double radius;
	std::ostringstream s;
	DWORD dw1 = GetTickCount();
	calcSEC(precision, filename, &radius, &secPoint, &secDirection);
	DWORD dw2 = GetTickCount();
	s << "==Debug Mode==: " << filename << ", Angle Precision: " << precision << ", Time: " << ((dw2 - dw1)/1000)/60 << "mins " << ((dw2 - dw1)/1000) % 60 << "secs" << "==";
	writeOutput(DEBUG_FILENAME, &radius, &secPoint, &secDirection, &s.str());
	return radius;
}

int main (int argc, char* argv[]) {
	double radius,radius01, radius05, radius1;
	myPoint secPoint, secDirection;
	int calc01pres;
	if (argc == 1) // regular mode, ran from within amira
	{
		calcSEC(ANGLE_PRESISION, FILE_NAME, &radius, &secPoint, &secDirection);
		writeOutput(FILE_NAME, &radius, &secPoint, &secDirection, NULL);
	}
	else if (argc == 2 && !strcmp(argv[1],"--debug_mode"))
	{
		debug_mode = true;
		
		vector<string> files;
		bool valid = listFiles(&files);
		if (!valid)
			return 0;
		//by default, calculate and compare [.5,1] Angular precision. ask user if wishes for 0.1 as well
		cout << "Should I calculate for 0.1 angle precision as well? (1=yes, 0=no)" << endl;
		cin >> calc01pres;
		// for each file; calcSEC; save data; print final report to same file with % mistake
		for (unsigned int i = 0; i < files.size(); i++)
		{
			string filename = files[i];
			if (calc01pres)
				radius01 = secDebugRoutine(filename,0.1);
			radius05 = secDebugRoutine(filename,0.5);
			radius1 = secDebugRoutine(filename,1);
			if (calc01pres)
				writeStatistics(filename,radius01,radius1, string("0.1"));
			else
				writeStatistics(filename,radius05,radius1, string("0.5"));
		}
	} else if(argc == 3 && !strcmp(argv[1],"--image_mode")) 
	{
		image_mode = true;
		calcSEC(atof(argv[2]), FILE_NAME, &radius, &secPoint, &secDirection);
		writeOutput(FILE_NAME, &radius, &secPoint, &secDirection, NULL);
		ofstream outfile;
		string outfilename(FILE_NAME);
		outfilename = outfilename.substr(0,outfilename.length() - 4) + "_image.txt";
		outfile.open(outfilename, fstream::app);
		outfile.precision(PRECISION);
		for (unsigned int i = 0; i < radiuses.size(); i++)
			outfile << radiuses.at(i) << " ";
		outfile.close();
	} else if (argc == 3)
	{
			calcSEC(atof(argv[1]), FILE_NAME, &radius, &secPoint, &secDirection,strcmp(argv[2],"--pca_opt=false"));
			writeOutput(FILE_NAME, &radius, &secPoint, &secDirection, NULL);
	} else
		cout << "Usage: sec.exe [--debug_mode]" << endl;

	return 0;
}
